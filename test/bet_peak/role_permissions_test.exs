defmodule BetPeak.RolePermissionsTest do
  use BetPeak.DataCase

  describe "role_permissions" do
    alias BetPeak.RolePermissions
    alias BetPeak.RolePermissions.RolePermission

    import BetPeak.AccountsFixtures,
      only: [
        user_scope_fixture: 0,
        super_admin_scope_fixture: 0,
        admin_scope_fixture: 0
      ]

    alias BetPeak.RolePermissionsFixtures
    alias BetPeak.AccessControlFixtures

    setup do
      AccessControlFixtures.setup_roles()

      %{
        super_admin_scope: super_admin_scope_fixture(),
        admin_scope: admin_scope_fixture(),
        user_scope: user_scope_fixture(),
        role: RolePermissionsFixtures.create_role(),
        permission: RolePermissionsFixtures.create_permission()
      }
    end

    test "change_creation/2 returns a role permission changeset", context do
      role_permission =
        RolePermissionsFixtures.add_role_permission(
          context.super_admin_scope,
          context.role.id,
          context.permission.id
        )

      assert %Ecto.Changeset{} =
               RolePermissions.change_creation(
                 role_permission,
                 %{
                   role_id: RolePermissionsFixtures.create_role().id,
                   permission_id: RolePermissionsFixtures.create_permission().id
                 }
               )
    end

    test "save/2 with valid data creates a role permission", context do
      assert {:ok, %RolePermission{} = role_permission} =
               RolePermissions.save(
                 context.super_admin_scope,
                 RolePermissionsFixtures.get_valid_attributes(
                   context.role.id,
                   context.permission.id
                 )
               )

      assert role_permission.role_id == context.role.id
    end

    test "save/2 with invalid data returns error changeset", context do
      assert {:error, %Ecto.Changeset{}} =
               RolePermissions.save(
                 context.super_admin_scope,
                 RolePermissionsFixtures.get_invalid_attributes()
               )
    end

    test "save/2 with valid data but admin tries to create a role permission", context do
      assert {:error, :unauthorized} =
               RolePermissions.save(
                 context.admin_scope,
                 RolePermissionsFixtures.get_valid_attributes(
                   context.role.id,
                   context.permission.id
                 )
               )
    end

    test "save2 with valid data but user tries to create a role permission", context do
      assert {:error, :unauthorized} =
               RolePermissions.save(
                 context.user_scope,
                 RolePermissionsFixtures.get_valid_attributes(
                   context.role.id,
                   context.permission.id
                 )
               )
    end

    test "save2 with valid data but role permission already exists", context do
      RolePermissions.save(
        context.super_admin_scope,
        RolePermissionsFixtures.get_valid_attributes(context.role.id, context.permission.id)
      )

      {:error, changeset} =
        RolePermissions.save(
          context.super_admin_scope,
          RolePermissionsFixtures.get_valid_attributes(context.role.id, context.permission.id)
        )

      assert %{permission_id: ["has already been taken"]} == errors_on(changeset)
    end

    test "delete/2 deletes the permission", context do
      role_permission =
        RolePermissionsFixtures.add_role_permission(
          context.super_admin_scope,
          context.role.id,
          context.permission.id
        )

      total_role_permissions = length(Repo.all(RolePermission))

      assert {:ok, %RolePermission{}} =
               RolePermissions.delete(context.super_admin_scope, role_permission)

      assert length(Repo.all(RolePermission)) == total_role_permissions - 1
    end

    test "delete_permission/2 with invalid scope raises", context do
      role_permission =
        RolePermissionsFixtures.add_role_permission(
          context.super_admin_scope,
          context.role.id,
          context.permission.id
        )

      assert {:error, :unauthorized} =
               RolePermissions.delete(context.admin_scope, role_permission)
    end
  end
end
