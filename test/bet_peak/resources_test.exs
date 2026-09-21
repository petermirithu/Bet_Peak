defmodule BetPeak.ResourcesTest do
  use BetPeak.DataCase

  describe "resources" do
    alias BetPeak.Resources
    alias BetPeak.Resources.Resource

    import BetPeak.AccountsFixtures,
      only: [
        user_scope_fixture: 0,
        super_admin_scope_fixture: 0,
        admin_scope_fixture: 0
      ]

    alias BetPeak.ResourcesFixtures
    alias BetPeak.AccessControlFixtures

    setup do
      AccessControlFixtures.setup_roles()

      %{
        super_admin_scope: super_admin_scope_fixture(),
        admin_scope: admin_scope_fixture(),
        user_scope: user_scope_fixture()
      }
    end

    test "change_resource/2 returns a resource changeset", context do
      resource = ResourcesFixtures.add_resource(context.super_admin_scope)

      assert %Ecto.Changeset{} =
               Resources.change_creation(
                 resource,
                 %{name: "new name"}
               )
    end

    test "save/2 with valid data creates a resource", context do
      valid_attr = ResourcesFixtures.get_valid_attributes()

      assert {:ok, %Resource{} = resource} =
               Resources.save(
                 context.super_admin_scope,
                 valid_attr
               )

      assert resource.name == valid_attr.name
    end

    test "save/2 with invalid data returns error changeset", context do
      assert {:error, %Ecto.Changeset{}} =
               Resources.save(
                 context.super_admin_scope,
                 ResourcesFixtures.get_invalid_attributes()
               )
    end

    test "save/2 with valid data but admin tries to create a resource", context do
      assert {:error, :unauthorized} =
               Resources.save(
                 context.admin_scope,
                 ResourcesFixtures.get_valid_attributes()
               )
    end

    test "save2 with valid data but user tries to create a resource", context do
      assert {:error, :unauthorized} =
               Resources.save(
                 context.user_scope,
                 ResourcesFixtures.get_valid_attributes()
               )
    end

    test "fetch_all!/2 returns all resources for super admin and none for unauthorized users",
         context do
      ResourcesFixtures.add_resources(context.super_admin_scope)

      assert length(Resources.fetch_all(context.super_admin_scope)) ==
               length(Repo.all(Resource))

      assert length(Resources.fetch_all(context.admin_scope)) == 0
      assert length(Resources.fetch_all(context.user_scope)) == 0
    end

    test "update/3 with valid data updates the resource", context do
      resource = ResourcesFixtures.add_resource(context.super_admin_scope)

      update_attrs = %{
        name: "some updated name"
      }

      assert {:ok, %Resource{} = resource} =
               Resources.update(context.super_admin_scope, resource, update_attrs)

      assert resource.name == "some updated name"
    end

    test "update/3 with invalid scope raises", context do
      resource = ResourcesFixtures.add_resource(context.super_admin_scope)

      assert {:error, :unauthorized} = Resources.update(context.admin_scope, resource, %{})
    end

    test "update/3 with invalid data returns error changeset", context do
      resource = ResourcesFixtures.add_resource(context.super_admin_scope)

      assert {:error, %Ecto.Changeset{}} =
               Resources.update(
                 context.super_admin_scope,
                 resource,
                 ResourcesFixtures.get_invalid_attributes()
               )
    end

    test "delete/2 deletes the resource", context do
      resource = ResourcesFixtures.add_resource(context.super_admin_scope)
      total_resources = length(Resources.fetch_all(context.super_admin_scope))

      assert {:ok, %Resource{}} = Resources.delete(context.super_admin_scope, resource)

      assert length(Resources.fetch_all(context.super_admin_scope)) == total_resources - 1
    end

    test "delete_resource/2 with invalid scope raises", context do
      resource = ResourcesFixtures.add_resource(context.super_admin_scope)
      assert {:error, :unauthorized} = Resources.delete(context.admin_scope, resource)
    end
  end
end
