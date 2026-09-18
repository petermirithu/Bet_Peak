defmodule BetPeak.AccessControlFixtures do
  use BetPeakWeb.ConnCase, async: true

  import Ecto.Query
  alias BetPeak.Repo

  alias BetPeak.Resources.Resource
  alias BetPeak.Permissions.Permission
  alias BetPeak.Roles.Role
  alias BetPeak.RolePermissions.RolePermission
  alias BetPeak.RoleInherits.RoleInherit
  alias BetPeak.UserRoles.UserRole

  defp setup_resource(name) do
    {:ok, resourse} = %Resource{name: name} |> Repo.insert()
    resourse
  end

  defp setup_permission(resource, action) do
    {:ok, permission} =
      %Permission{resource_id: resource.id, action: action}
      |> Repo.insert()

    permission
  end

  defp setup_role(name) do
    {:ok, role} = %Role{name: name} |> Repo.insert()
    role
  end

  defp setup_role_permission(role, permission) do
    %RolePermission{role_id: role.id, permission_id: permission.id}
    |> Repo.insert()
  end

  defp setup_role_inherits(parent_role, child_role) do
    %RoleInherit{parent_role_id: parent_role.id, child_role_id: child_role.id}
    |> Repo.insert()
  end

  defp setup_sports_permissions(super_admin, admin) do
    # Sports section
    resource_1 = setup_resource("Sports")

    permission_1 = setup_permission(resource_1, "Create")
    permission_2 = setup_permission(resource_1, "Read")
    permission_3 = setup_permission(resource_1, "Update")
    permission_4 = setup_permission(resource_1, "Delete")

    # admin can read sports
    setup_role_permission(admin, permission_2)

    # super admin does CUD on sports
    setup_role_permission(super_admin, permission_1)
    setup_role_permission(super_admin, permission_3)
    setup_role_permission(super_admin, permission_4)
  end

  def setup_roles do
    super_admin = setup_role("Super Admin")
    admin = setup_role("Admin")
    user = setup_role("User")

    setup_role_inherits(user, admin)
    setup_role_inherits(admin, super_admin)

    setup_sports_permissions(super_admin, admin)
  end

  def convert_user_to_admin(user, admin_option) do
    role_user_id = from(role in Role, where: role.name == "User") |> Repo.one() |> Map.get(:id)

    role_admin_id =
      from(role in Role, where: role.name == ^admin_option) |> Repo.one() |> Map.get(:id)

    user_s_role =
      from(user_role in UserRole,
        where: user_role.user_id == ^user.id and user_role.role_id == ^role_user_id
      )
      |> Repo.one()

    user_s_role
    |> Ecto.Changeset.change(%{role_id: role_admin_id})
    |> Repo.update()

    user
  end
end
