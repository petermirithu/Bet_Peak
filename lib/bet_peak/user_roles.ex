defmodule BetPeak.UserRoles do
  import Ecto.Query, warn: false

  alias BetPeak.Repo
  alias BetPeak.UserRoles.UserRole
  alias BetPeak.Authorization
  alias BetPeak.Accounts.Scope
  alias BetPeak.Roles.Role

  def assign_user_to_new_user(result) do
    # For new users signing up!!!!!
    case result do
      {:ok, user} ->
        %UserRole{
          user_id: user.id,
          role_id: from(role in Role, where: role.name == "User") |> Repo.one() |> Map.get(:id)
        }
        |> UserRole.changeset(%{}, [])
        |> Repo.insert()

        result

      _ ->
        result
    end
  end

  def save(%Scope{} = current_scope, attrs) do
    case Authorization.authorize!(current_scope, "Access Control", "create") do
      :ok ->
        %UserRole{}
        |> UserRole.changeset(attrs, [])
        |> Repo.insert()

      :unauthorized ->
        {:error, :unauthorized}
    end
  end

  def change_creation(user_role, attrs \\ %{}, opts \\ []) do
    UserRole.changeset(user_role, attrs, opts)
  end

  def delete(%Scope{} = current_scope, %UserRole{} = user_role) do
    case Authorization.authorize!(current_scope, "Access Control", "delete") do
      :ok ->
        user_role
        |> Repo.delete()

      :unauthorized ->
        {:error, :unauthorized}
    end
  end
end
