defmodule BetPeak.RoleInheritsTest do
  use BetPeak.DataCase

  describe "role_inherits" do
    alias BetPeak.RoleInherits
    alias BetPeak.RoleInherits.RoleInherit

    import BetPeak.AccountsFixtures,
      only: [
        user_scope_fixture: 0,
        super_admin_scope_fixture: 0,
        admin_scope_fixture: 0
      ]

    alias BetPeak.RoleInheritsFixtures
    alias BetPeak.AccessControlFixtures

    setup do
      AccessControlFixtures.setup_roles()

      %{
        super_admin_scope: super_admin_scope_fixture(),
        admin_scope: admin_scope_fixture(),
        user_scope: user_scope_fixture(),
        parent_role: RoleInheritsFixtures.create_role(),
        child_role: RoleInheritsFixtures.create_role()
      }
    end

    test "change_creation/2 returns a role inherit changeset", context do
      role_inherit =
        RoleInheritsFixtures.add_role_inherit(
          context.super_admin_scope,
          context.parent_role.id,
          context.child_role.id
        )

      assert %Ecto.Changeset{} =
               RoleInherits.change_creation(
                 role_inherit,
                 %{
                   parent_role_id: RoleInheritsFixtures.create_role().id,
                   child_role_id: RoleInheritsFixtures.create_role().id
                 }
               )
    end

    test "save/2 with valid data creates a role inherit", context do
      assert {:ok, %RoleInherit{} = role_inherit} =
               RoleInherits.save(
                 context.super_admin_scope,
                 RoleInheritsFixtures.get_valid_attributes(
                   context.parent_role.id,
                   context.child_role.id
                 )
               )

      assert role_inherit.parent_role_id == context.parent_role.id
      assert role_inherit.child_role_id == context.child_role.id
    end

    test "save/2 with invalid data returns error changeset", context do
      assert {:error, %Ecto.Changeset{}} =
               RoleInherits.save(
                 context.super_admin_scope,
                 RoleInheritsFixtures.get_invalid_attributes()
               )
    end

    test "save/2 with valid data but admin tries to create a role inherit", context do
      assert {:error, :unauthorized} =
               RoleInherits.save(
                 context.admin_scope,
                 RoleInheritsFixtures.get_valid_attributes(
                   context.parent_role.id,
                   context.child_role.id
                 )
               )
    end

    test "save2 with valid data but user tries to create a role inherit", context do
      assert {:error, :unauthorized} =
               RoleInherits.save(
                 context.user_scope,
                 RoleInheritsFixtures.get_valid_attributes(
                   context.parent_role.id,
                   context.child_role.id
                 )
               )
    end

    test "save2 with valid data but role inherit already exists", context do
      RoleInherits.save(
        context.super_admin_scope,
        RoleInheritsFixtures.get_valid_attributes(context.parent_role.id, context.child_role.id)
      )

      {:error, changeset} =
        RoleInherits.save(
          context.super_admin_scope,
          RoleInheritsFixtures.get_valid_attributes(context.parent_role.id, context.child_role.id)
        )

      assert %{parent_role_id: ["has already been taken"]} == errors_on(changeset)
    end

    test "delete/2 deletes the role inherit", context do
      role_inherit =
        RoleInheritsFixtures.add_role_inherit(
          context.super_admin_scope,
          context.parent_role.id,
          context.child_role.id
        )

      total_role_inherits = length(Repo.all(RoleInherit))

      assert {:ok, %RoleInherit{}} =
               RoleInherits.delete(context.super_admin_scope, role_inherit)

      assert length(Repo.all(RoleInherit)) == total_role_inherits - 1
    end

    test "delete_permission/2 with invalid scope raises", context do
      role_inherit =
        RoleInheritsFixtures.add_role_inherit(
          context.super_admin_scope,
          context.parent_role.id,
          context.child_role.id
        )

      assert {:error, :unauthorized} =
               RoleInherits.delete(context.admin_scope, role_inherit)
    end
  end
end
