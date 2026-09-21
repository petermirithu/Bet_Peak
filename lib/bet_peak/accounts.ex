defmodule BetPeak.Accounts do
  import Ecto.Query, warn: false
  alias BetPeak.Workers
  alias BetPeak.Repo
  alias BetPeak.Accounts.Scope
  alias BetPeak.Accounts.{User, UserToken, UserNotifier}
  alias BetPeak.UserRoles
  alias BetPeak.Authorization

  ## Database getters
  def get_all_users(%Scope{} = current_scope) do
    case Authorization.authorize!(current_scope, "Users", "read") do
      :ok ->
        from(user in User, where: is_nil(user.deleted_at))
        |> Repo.all()
        |> Repo.preload(
          user_roles: [
            role: [
              parent_inheritances: :parent_role,
              role_permissions: [permission: :resource]
            ]
          ]
        )

      :unauthorized ->
        []
    end
  end

  def get_user_by_email_and_password(email, password)
      # No scope fetch user during login
      when is_binary(email) and is_binary(password) do
    user =
      from(user in User, where: user.email == ^email and is_nil(user.deleted_at))
      |> Repo.one()

    if User.valid_password?(user, password), do: user
  end

  def register_user(attrs) do
    # No scope due since it creates one.
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
    |> UserRoles.assign_user_to_new_user()
  end

  def change_user_registration(user, attrs \\ %{}, opts \\ []) do
    User.registration_changeset(user, attrs, opts)
  end

  def get_user_token_by_context(%Scope{} = current_scope, context) do
    case Authorization.authorize!(current_scope, "Users", "read") do
      :ok ->
        Repo.all_by(UserToken, user_id: current_scope.user.id, context: context)

      :unauthorized ->
        {:error, :unauthorized}
    end
  end

  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  def send_email_update_confirmation_link(%Scope{} = current_scope, attrs \\ %{}, opts \\ []) do
    case Authorization.authorize!(current_scope, "Users", "update") do
      :ok ->
        User.email_changeset(current_scope.user, attrs, opts)

      :unauthorized ->
        {:error, :unauthorized}
    end
  end

  def update_user_email(%Scope{} = current_scope, token) do
    case Authorization.authorize!(current_scope, "Users", "update") do
      :ok ->
        context = "change:#{current_scope.user.email}"

        Repo.transact(fn ->
          with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
               %UserToken{sent_to: email} <- Repo.one(query),
               {:ok, user} <-
                 Repo.update(User.email_changeset(current_scope.user, %{email: email})),
               {_count, _result} <-
                 Repo.delete_all(
                   from(UserToken, where: [user_id: ^current_scope.user.id, context: ^context])
                 ) do
            {:ok, user}
          else
            _ -> {:error, :transaction_aborted}
          end
        end)

      :unauthorized ->
        {:error, :unauthorized}
    end
  end

  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  def update_user_password(%Scope{} = current_scope, attrs) do
    case Authorization.authorize!(current_scope, "Users", "update") do
      :ok ->
        current_scope.user
        |> User.password_changeset(attrs)
        |> update_user_and_delete_all_tokens()

      :unauthorized ->
        {:error, :unauthorized}
    end
  end

  @spec generate_user_session_token(any()) :: binary()
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  def check_if_confirmed(user) do
    case user do
      %{confirmed_at: nil} ->
        {:ok, :not_confirmed}

      _ ->
        {:ok, :confirmed}
    end
  end

  def confirm_new_user_account(token) do
    {:ok, query} = UserToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      {%User{confirmed_at: nil} = user, _token} ->
        user
        |> User.confirm_changeset()
        |> update_user_and_delete_all_tokens()

      {user, token} ->
        Repo.delete!(token)
        {:ok, {user, []}}

      nil ->
        {:error, :not_found}
    end
  end

  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      # Already scoped by send_email_update_confirmation_link function
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  def deliver_login_instructions(%Scope{} = current_scope, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    case Authorization.authorize!(current_scope, "Users", "read") do
      :ok ->
        {encoded_token, user_token} = UserToken.build_email_token(current_scope.user, "login")

        Repo.insert!(user_token)

        UserNotifier.deliver_login_instructions(
          current_scope.user,
          magic_link_url_fun.(encoded_token)
        )

      :unauthorized ->
        {:error, :unauthorized}
    end
  end

  def delete_user_session_token(%Scope{} = current_scope, token) do
    # case Authorization.authorize!(current_scope, "Users", "delete") do
    # :ok ->
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok

    # :unauthorized ->
    # {:error, :unauthorized}
    # end
  end

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)

        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))

        {:ok, {user, tokens_to_expire}}
      end
    end)
  end

  def delete_user(%Scope{} = current_scope, user) do
    case Authorization.authorize!(current_scope, "Users", "delete") do
      :ok ->
        changeset =
          user
          |> Ecto.Changeset.change(%{
            deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)
          })
          |> Repo.update()
          |> Workers.SoftDelete.delete_children_records("user_bets")

        from(token in UserToken, where: token.user_id == ^user.id)
        |> Repo.delete_all()

        changeset

      :unauthorized ->
        {:error, :unauthorized}
    end
  end
end
