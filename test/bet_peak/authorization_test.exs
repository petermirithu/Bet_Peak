defmodule BetPeak.AuthorizationTest do
  use BetPeak.DataCase, async: true

  import BetPeak.AccountsFixtures

  alias BetPeak.Accounts.Scope
  alias BetPeak.Authorization
  alias BetPeak.Permissions.Permission
  alias BetPeak.Resources.Resource
  alias BetPeak.RoleInherits.RoleInherit
  alias BetPeak.RolePermissions.RolePermission
  alias BetPeak.Roles
  alias BetPeak.Roles.Role
  alias BetPeak.UserRoles.UserRole

  test "authorizes a permission inherited through multiple parent roles" do
    user = unconfirmed_user_fixture()
    user_role = insert_role!("User")
    admin_role = insert_role!("Admin")
    super_admin_role = insert_role!("Super Admin")

    resource = Repo.insert!(%Resource{name: "Admin Routes"})
    permission = Repo.insert!(%Permission{action: "Read", resource_id: resource.id})
    update_permission = Repo.insert!(%Permission{action: "Update", resource_id: resource.id})

    Repo.insert!(%UserRole{user_id: user.id, role_id: super_admin_role.id})

    Repo.insert!(%RoleInherit{
      parent_role_id: admin_role.id,
      child_role_id: super_admin_role.id
    })

    Repo.insert!(%RoleInherit{
      parent_role_id: user_role.id,
      child_role_id: admin_role.id
    })

    Repo.insert!(%RolePermission{role_id: admin_role.id, permission_id: permission.id})
    Repo.insert!(%RolePermission{role_id: super_admin_role.id, permission_id: permission.id})

    Repo.insert!(%RolePermission{
      role_id: super_admin_role.id,
      permission_id: update_permission.id
    })

    scope = Scope.for_user(user)
    roles = Roles.fetch_all(scope)
    loaded_super_admin = Enum.find(roles, &(&1.id == super_admin_role.id))

    assert Authorization.permitted?(scope, "admin routes", "read")
    assert Authorization.authorize!(scope, "Admin Routes", "READ") == :ok
    refute Authorization.permitted?(scope, "Admin Routes", "delete")
    assert loaded_super_admin.effective_permission_count == 2
  end

  test "denies a user without an assigned role" do
    scope = unconfirmed_user_fixture() |> Scope.for_user()

    refute Authorization.permitted?(scope, "Admin Routes", "read")
    assert Authorization.authorize!(scope, "Admin Routes", "read") == :unauthorized
  end

  test "denies a missing scope" do
    refute Authorization.permitted?(nil, "Admin Routes", "read")
  end

  defp insert_role!(name), do: Repo.insert!(%Role{name: name})
end
