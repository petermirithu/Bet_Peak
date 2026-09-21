defmodule BetPeak.RolesTest do
  use BetPeak.DataCase

  describe "roles" do
    alias BetPeak.Roles
    alias BetPeak.Roles.Role

    import BetPeak.AccountsFixtures,
      only: [
        user_scope_fixture: 0,
        super_admin_scope_fixture: 0,
        admin_scope_fixture: 0
      ]

    alias BetPeak.RolesFixtures
    alias BetPeak.AccessControlFixtures

    setup do
      AccessControlFixtures.setup_roles()

      %{
        super_admin_scope: super_admin_scope_fixture(),
        admin_scope: admin_scope_fixture(),
        user_scope: user_scope_fixture()
      }
    end

    test "change_role/2 returns a roles changeset", context do
      role = RolesFixtures.add_role(context.super_admin_scope)

      assert %Ecto.Changeset{} =
               Roles.change_creation(
                 role,
                 %{name: "new name"}
               )
    end

    test "save/2 with valid data creates a role", context do
      valid_attr = RolesFixtures.get_valid_attributes()

      assert {:ok, %Role{} = role} =
               Roles.save(
                 context.super_admin_scope,
                 valid_attr
               )

      assert role.name == valid_attr.name
    end

    test "save/2 with invalid data returns error changeset", context do
      assert {:error, %Ecto.Changeset{}} =
               Roles.save(
                 context.super_admin_scope,
                 RolesFixtures.get_invalid_attributes()
               )
    end

    test "save/2 with valid data but admin tries to create a role", context do
      assert {:error, :unauthorized} =
               Roles.save(
                 context.admin_scope,
                 RolesFixtures.get_valid_attributes()
               )
    end

    test "save2 with valid data but user tries to create a role", context do
      assert {:error, :unauthorized} =
               Roles.save(
                 context.user_scope,
                 RolesFixtures.get_valid_attributes()
               )
    end

    test "fetch_all!/2 returns all roles for super admin and none for unauthorized users",
         context do
      RolesFixtures.add_roles(context.super_admin_scope)

      assert length(Roles.fetch_all(context.super_admin_scope)) ==
               length(Repo.all(Role))

      assert length(Roles.fetch_all(context.admin_scope)) == 0
      assert length(Roles.fetch_all(context.user_scope)) == 0
    end

    test "update/3 with valid data updates the role", context do
      role = RolesFixtures.add_role(context.super_admin_scope)

      update_attrs = %{
        name: "some updated name"
      }

      assert {:ok, %Role{} = role} =
               Roles.update(context.super_admin_scope, role, update_attrs)

      assert role.name == "some updated name"
    end

    test "update/3 with invalid scope raises", context do
      role = RolesFixtures.add_role(context.super_admin_scope)

      assert {:error, :unauthorized} = Roles.update(context.admin_scope, role, %{})
    end

    test "update/3 with invalid data returns error changeset", context do
      role = RolesFixtures.add_role(context.super_admin_scope)

      assert {:error, %Ecto.Changeset{}} =
               Roles.update(
                 context.super_admin_scope,
                 role,
                 RolesFixtures.get_invalid_attributes()
               )
    end

    test "delete/2 deletes the role", context do
      role = RolesFixtures.add_role(context.super_admin_scope)
      total_roles = length(Roles.fetch_all(context.super_admin_scope))

      assert {:ok, %Role{}} = Roles.delete(context.super_admin_scope, role)

      assert length(Roles.fetch_all(context.super_admin_scope)) == total_roles - 1
    end

    test "delete_role/2 with invalid scope raises", context do
      role = RolesFixtures.add_role(context.super_admin_scope)
      assert {:error, :unauthorized} = Roles.delete(context.admin_scope, role)
    end
  end
end
