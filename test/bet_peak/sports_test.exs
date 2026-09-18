defmodule BetPeak.SportsTest do
  use BetPeak.DataCase

  alias BetPeak.Sports

  describe "sports" do
    alias BetPeak.Sports.Sport

    import BetPeak.AccountsFixtures,
      only: [
        user_scope_fixture: 0,
        super_admin_scope_fixture: 0,
        admin_scope_fixture: 0
      ]

    alias BetPeak.SportsFixtures
    alias BetPeak.AccessControlFixtures

    setup do
      AccessControlFixtures.setup_roles()

      %{
        super_admin_scope: super_admin_scope_fixture(),
        admin_scope: admin_scope_fixture(),
        user_scope: user_scope_fixture()
      }
    end

    test "change_sport/2 returns a sport changeset", context do
      sport = SportsFixtures.add_sport(context.super_admin_scope)

      assert %Ecto.Changeset{} =
               Sports.change_sport_creation(
                 sport,
                 %{name: "new name"}
               )
    end

    test "save_sport/2 with valid data creates a sport", context do
      valid_attr = SportsFixtures.get_valid_attributes(context.super_admin_scope.user.id)

      assert {:ok, %Sport{} = sport} =
               Sports.save_sport(
                 context.super_admin_scope,
                 valid_attr
               )

      assert sport.active == valid_attr.active
      assert sport.name == valid_attr.name
      assert sport.description == valid_attr.description
      assert sport.user_id == context.super_admin_scope.user.id
    end

    test "save_sport/2 with invalid data returns error changeset", context do
      assert {:error, %Ecto.Changeset{}} =
               Sports.save_sport(
                 context.super_admin_scope,
                 SportsFixtures.get_invalid_attributes(0)
               )
    end

    test "save_sport/2 with valid data but admin tries to create a sport", context do
      assert {:error, :unauthorized} =
               Sports.save_sport(
                 context.admin_scope,
                 SportsFixtures.get_valid_attributes(context.admin_scope.user.id)
               )
    end

    test "save_sport/2 with valid data but user tries to create a sport", context do
      assert {:error, :unauthorized} =
               Sports.save_sport(
                 context.user_scope,
                 SportsFixtures.get_valid_attributes(context.user_scope.user.id)
               )
    end

    test "fetch_all_active/1 returns all active sports", context do
      SportsFixtures.add_sports(context.super_admin_scope)
      assert length(Sports.fetch_all_active(context.super_admin_scope)) == 2
      assert length(Sports.fetch_all_active(context.admin_scope)) == 2
      assert [] = Sports.fetch_all_active(context.user_scope)
    end

    test "fetch_all!/2 returns all active and inactive sports", context do
      SportsFixtures.add_sports(context.super_admin_scope)
      assert length(Sports.fetch_all(context.super_admin_scope)) == 3
      assert length(Sports.fetch_all(context.admin_scope)) == 3
      assert length(Sports.fetch_all(context.user_scope)) == 0
    end

    test "update_sport/3 with valid data updates the sport", context do
      sport = SportsFixtures.add_sport(context.super_admin_scope)

      update_attrs = %{
        active: false,
        name: "some updated name",
        description: "some updated description"
      }

      assert {:ok, %Sport{} = sport} =
               Sports.update_sport(context.super_admin_scope, sport, update_attrs)

      assert sport.active == false
      assert sport.name == "some updated name"
      assert sport.description == "some updated description"
    end

    test "update_sport/3 with invalid scope raises", context do
      sport = SportsFixtures.add_sport(context.super_admin_scope)

      assert {:error, :unauthorized} = Sports.update_sport(context.admin_scope, sport, %{})
    end

    test "update_sport/3 with invalid data returns error changeset", context do
      sport = SportsFixtures.add_sport(context.super_admin_scope)

      assert {:error, %Ecto.Changeset{}} =
               Sports.update_sport(
                 context.super_admin_scope,
                 sport,
                 SportsFixtures.get_invalid_attributes(0)
               )
    end

    test "delete_sport/2 deletes the sport", context do
      sport = SportsFixtures.add_sport(context.super_admin_scope)
      assert {:ok, %Sport{}} = Sports.delete_sport(context.super_admin_scope, sport)
      assert [] == Sports.fetch_all_active(context.super_admin_scope)

      soft_deleted_sport =
        from(d_sport in Sport, where: d_sport.id == ^sport.id) |> Repo.one()

      assert is_nil(soft_deleted_sport.deleted_at) == false
    end

    test "delete_sport/2 with invalid scope raises", context do
      sport = SportsFixtures.add_sport(context.super_admin_scope)
      assert {:error, :unauthorized} = Sports.delete_sport(context.admin_scope, sport)
    end
  end
end
