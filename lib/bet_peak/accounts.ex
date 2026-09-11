defmodule BetPeak.Accounts do
  import Ecto.Query, warn: false
  alias BetPeak.Workers
  alias BetPeak.Repo

  alias BetPeak.Accounts.{User, UserToken, UserNotifier}

  ## Database getters
  def get_all_users() do
    from(user in User, where: is_nil(user.deleted_at))
    |> Repo.all()
  end

  def get_user_by_email(email) when is_binary(email) do
    from(user in User, where: user.email == ^email and is_nil(user.deleted_at))
    |> Repo.one()
  end

  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = get_user_by_email(email)
    if User.valid_password?(user, password), do: user
  end

  def get_user!(id) do
    Repo.get_by!(User, id: id, deleted_at: nil)
  end

  def change_user_access(%User{} = user, attrs \\ %{}) do
    User.access_changeset(user, attrs)
  end

  def update_user_access(%User{} = user, attrs) do
    user
    |> User.access_changeset(attrs)
    |> Repo.update()
  end

  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def change_user_registration(user, attrs \\ %{}, opts \\ []) do
    User.registration_changeset(user, attrs, opts)
  end

  def get_user_token_by_context(user_id, context) do
    Repo.all_by(UserToken, user_id: user_id, context: context)
  end

  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, user}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

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
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  def deliver_login_instructions(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")

    Repo.insert!(user_token)
    UserNotifier.deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
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

  def delete_user(user) do
    # For admins, we dont want to delete sports, teams and games added by them.
    changeset =
      user
      |> Ecto.Changeset.change(%{deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)})
      |> Repo.update()
      |> Workers.SoftDelete.delete_children_records("user_bets")

    from(token in UserToken, where: token.user_id == ^user.id)
    |> Repo.delete_all()

    changeset
  end
end
