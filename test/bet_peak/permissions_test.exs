defmodule BetPeak.PermissionsTest do
  use BetPeak.DataCase

  describe "permissions" do
    alias BetPeak.Permissions
    alias BetPeak.Permissions.Permission

    import BetPeak.AccountsFixtures,
      only: [
        user_scope_fixture: 0,
        super_admin_scope_fixture: 0,
        admin_scope_fixture: 0
      ]

    alias BetPeak.PermissionsFixtures
    alias BetPeak.AccessControlFixtures

    setup do
      AccessControlFixtures.setup_roles()

      %{
        super_admin_scope: super_admin_scope_fixture(),
        admin_scope: admin_scope_fixture(),
        user_scope: user_scope_fixture(),
        resource: PermissionsFixtures.get_resource()
      }
    end

    test "change_creation/2 returns a permission changeset", context do
      permission = PermissionsFixtures.add_permission(context.super_admin_scope)

      assert %Ecto.Changeset{} =
               Permissions.change_creation(
                 permission,
                 %{action: "new action"}
               )
    end

    test "save/2 with valid data creates a permission", context do
      valid_attr = PermissionsFixtures.get_valid_attributes(context.resource.id)

      assert {:ok, %Permission{} = permission} =
               Permissions.save(
                 context.super_admin_scope,
                 valid_attr
               )

      assert permission.action == valid_attr.action
    end

    test "save/2 with invalid data returns error changeset", context do
      assert {:error, %Ecto.Changeset{}} =
               Permissions.save(
                 context.super_admin_scope,
                 PermissionsFixtures.get_invalid_attributes()
               )
    end

    test "save/2 with valid data but admin tries to create a permission", context do
      assert {:error, :unauthorized} =
               Permissions.save(
                 context.admin_scope,
                 PermissionsFixtures.get_valid_attributes(context.resource.id)
               )
    end

    test "save2 with valid data but user tries to create a permission", context do
      assert {:error, :unauthorized} =
               Permissions.save(
                 context.user_scope,
                 PermissionsFixtures.get_valid_attributes(context.resource.id)
               )
    end

    test "fetch_all!/2 returns all resources for super admin and none for unauthorized users",
         context do
      PermissionsFixtures.add_permissions(context.super_admin_scope)

      assert length(Permissions.fetch_all(context.super_admin_scope)) ==
               length(Repo.all(Permission))

      assert length(Permissions.fetch_all(context.admin_scope)) == 0
      assert length(Permissions.fetch_all(context.user_scope)) == 0
    end

    test "update/3 with valid data updates the permission", context do
      permission = PermissionsFixtures.add_permission(context.super_admin_scope)

      update_attrs = %{
        action: "some updated action"
      }

      assert {:ok, %Permission{} = permission} =
               Permissions.update(context.super_admin_scope, permission, update_attrs)

      assert permission.action == "some updated action"
    end

    test "update/3 with invalid scope raises", context do
      permission = PermissionsFixtures.add_permission(context.super_admin_scope)

      assert {:error, :unauthorized} = Permissions.update(context.admin_scope, permission, %{})
    end

    test "update/3 with invalid data returns error changeset", context do
      permission = PermissionsFixtures.add_permission(context.super_admin_scope)

      assert {:error, %Ecto.Changeset{}} =
               Permissions.update(
                 context.super_admin_scope,
                 permission,
                 PermissionsFixtures.get_invalid_attributes()
               )
    end

    test "delete/2 deletes the permission", context do
      permission = PermissionsFixtures.add_permission(context.super_admin_scope)
      total_permissions = length(Permissions.fetch_all(context.super_admin_scope))

      assert {:ok, %Permission{}} = Permissions.delete(context.super_admin_scope, permission)

      assert length(Permissions.fetch_all(context.super_admin_scope)) == total_permissions - 1
    end

    test "delete_permission/2 with invalid scope raises", context do
      permission = PermissionsFixtures.add_permission(context.super_admin_scope)
      assert {:error, :unauthorized} = Permissions.delete(context.admin_scope, permission)
    end
  end
end
