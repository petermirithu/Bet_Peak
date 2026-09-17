defmodule BetPeak.RolePermissions do
  import Ecto.Query, warn: false

  alias BetPeak.Repo
  alias BetPeak.RolePermissions.RolePermission
  alias BetPeak.Authorization
  alias BetPeak.Accounts.Scope

  def save(%Scope{} = current_scope, attrs) do
    case Authorization.authorize!(current_scope, "Access Control", "create") do
      :ok ->
        %RolePermission{}
        |> RolePermission.changeset(attrs, [])
        |> Repo.insert()

      :unauthorized ->
        {:error, :unauthorized}
    end
  end

  def change_creation(role_permission, attrs \\ %{}, opts \\ []) do
    RolePermission.changeset(role_permission, attrs, opts)
  end

  def delete(%Scope{} = current_scope, %RolePermission{} = role_permission) do
    case Authorization.authorize!(current_scope, "Access Control", "delete") do
      :ok ->
        Repo.delete(role_permission)

      :unauthorized ->
        {:error, :unauthorized}
    end
  end
end
