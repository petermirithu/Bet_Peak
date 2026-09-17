defmodule BetPeak.Roles do
  import Ecto.Query, warn: false

  alias BetPeak.Repo
  alias BetPeak.Roles.Role
  alias BetPeak.Accounts.Scope
  alias BetPeak.Authorization
  alias BetPeak.RoleInherits.RoleInherit
  alias BetPeak.RolePermissions.RolePermission

  def save(%Scope{} = current_scope, attrs) do
    case Authorization.authorize!(current_scope, "Access Control", "create") do
      :ok ->
        %Role{}
        |> Role.changeset(attrs, [])
        |> Repo.insert()

      :unauthorized ->
        {:error, :unauthorized}
    end
  end

  def fetch_all(%Scope{} = current_scope) do
    case Authorization.authorize!(current_scope, "Access Control", "read") do
      :ok ->
        permission_counts = effective_permission_counts()

        roles =
          from(role in Role)
          |> Repo.all()
          |> Repo.preload(:parent_inheritances)
          |> Repo.preload(parent_inheritances: :parent_role)
          |> Repo.preload(:role_permissions)
          |> Repo.preload(role_permissions: :permission)
          |> Repo.preload(role_permissions: [permission: :resource])

        Enum.map(roles, fn role ->
          %{role | effective_permission_count: Map.get(permission_counts, role.id, 0)}
        end)

      :unauthorized ->
        []
    end
  end

  defp effective_permission_counts do
    direct_roles =
      from(role in Role,
        select: %{role_id: role.id, effective_role_id: role.id}
      )

    inherited_roles =
      from(role_inherit in RoleInherit,
        join: effective_role in "effective_roles",
        on: effective_role.effective_role_id == role_inherit.child_role_id,
        select: %{
          role_id: effective_role.role_id,
          effective_role_id: role_inherit.parent_role_id
        }
      )

    effective_roles = union(direct_roles, ^inherited_roles)

    from(effective_role in "effective_roles",
      join: role_permission in RolePermission,
      on: role_permission.role_id == effective_role.effective_role_id,
      group_by: effective_role.role_id,
      select: {effective_role.role_id, count(role_permission.permission_id, :distinct)}
    )
    |> recursive_ctes(true)
    |> with_cte("effective_roles", as: ^effective_roles)
    |> Repo.all()
    |> Map.new()
  end

  def change_creation(role, attrs \\ %{}, opts \\ []) do
    Role.changeset(role, attrs, opts)
  end

  def update(%Scope{} = current_scope, role, attrs) do
    case Authorization.authorize!(current_scope, "Access Control", "update") do
      :ok ->
        role
        |> Role.changeset(attrs, [])
        |> Repo.update()

      :unauthorized ->
        {:error, :unauthorized}
    end
  end

  def delete(%Scope{} = current_scope, %Role{} = role) do
    case Authorization.authorize!(current_scope, "Access Control", "delete") do
      :ok ->
        Repo.delete(role)

      :unauthorized ->
        {:error, :unauthorized}
    end
  end
end
