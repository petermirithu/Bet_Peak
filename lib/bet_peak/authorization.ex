defmodule BetPeak.Authorization do
  import Ecto.Query, warn: false

  alias BetPeak.Accounts.Scope
  alias BetPeak.Permissions.Permission
  alias BetPeak.Repo
  alias BetPeak.Resources.Resource
  alias BetPeak.RoleInherits.RoleInherit
  alias BetPeak.RolePermissions.RolePermission
  alias BetPeak.Roles.Role
  alias BetPeak.UserRoles.UserRole

  def authorize!(%Scope{} = current_scope, resource, action) do
    if permitted?(current_scope, resource, action) do
      :ok
    else
      :unauthorized
    end
  end

  def permitted?(
        %Scope{user: %{id: user_id}},
        resource_name,
        action
      )
      when is_binary(resource_name) and is_binary(action) do
    direct_roles =
      from(user_role in UserRole,
        join: role in Role,
        on: role.id == user_role.role_id,
        where: user_role.user_id == ^user_id,
        select: %{role_id: user_role.role_id}
      )

    inherited_roles =
      from(role_inherit in RoleInherit,
        join: effective_role in "effective_roles",
        on: effective_role.role_id == role_inherit.child_role_id,
        join: parent_role in Role,
        on: parent_role.id == role_inherit.parent_role_id,
        select: %{role_id: role_inherit.parent_role_id}
      )

    effective_roles = union(direct_roles, ^inherited_roles)

    from(permission in Permission,
      join: role_permission in RolePermission,
      on: role_permission.permission_id == permission.id,
      join: effective_role in "effective_roles",
      on: effective_role.role_id == role_permission.role_id,
      join: resource in Resource,
      on: resource.id == permission.resource_id,
      where:
        fragment("lower(?)", permission.action) == ^String.downcase(action) and
          fragment("lower(?)", resource.name) == ^String.downcase(resource_name),
      select: 1
    )
    |> recursive_ctes(true)
    |> with_cte("effective_roles", as: ^effective_roles)
    |> Repo.exists?()
  end

  def permitted?(%Scope{}, _resource, _action), do: false
  def permitted?(_scope, _resource, _action), do: false
end
