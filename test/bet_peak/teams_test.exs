defmodule BetPeak.TeamsTest do
  use BetPeak.DataCase

  describe "teams" do
    alias BetPeak.Teams
    alias BetPeak.Teams.Team

    import BetPeak.AccountsFixtures,
      only: [
        user_scope_fixture: 0,
        super_admin_scope_fixture: 0,
        admin_scope_fixture: 0
      ]

    alias BetPeak.TeamsFixtures
    alias BetPeak.AccessControlFixtures

    setup do
      AccessControlFixtures.setup_roles()
      super_admin_scope = super_admin_scope_fixture()

      %{
        super_admin_scope: super_admin_scope,
        admin_scope: admin_scope_fixture(),
        user_scope: user_scope_fixture(),
        sport: TeamsFixtures.create_sport(super_admin_scope.user.id)
      }
    end

    test "change_team/2 returns a team changeset", context do
      team = TeamsFixtures.add_team(context.super_admin_scope, context.sport.id)

      assert %Ecto.Changeset{} =
               Teams.change_team_creation(
                 team,
                 %{name: "new name"}
               )
    end

    test "save_team/2 with valid data creates a team", context do
      valid_attr =
        TeamsFixtures.get_valid_attributes(
          context.super_admin_scope.user.id,
          context.sport.id
        )

      assert {:ok, %Team{} = team} =
               Teams.save_team(
                 context.super_admin_scope,
                 valid_attr
               )

      assert team.name == valid_attr.name
      assert team.about == valid_attr.about
      assert team.short_form == valid_attr.short_form
      assert team.user_id == context.super_admin_scope.user.id
    end

    test "save_team/2 with invalid data returns error changeset", context do
      assert {:error, %Ecto.Changeset{}} =
               Teams.save_team(
                 context.super_admin_scope,
                 TeamsFixtures.get_invalid_attributes()
               )
    end

    test "save_team/2 with valid data but admin tries to create a team", context do
      assert {:error, :unauthorized} =
               Teams.save_team(
                 context.admin_scope,
                 TeamsFixtures.get_valid_attributes(context.admin_scope.user.id, context.sport.id)
               )
    end

    test "save_team/2 with valid data but user tries to create a team", context do
      assert {:error, :unauthorized} =
               Teams.save_team(
                 context.user_scope,
                 TeamsFixtures.get_valid_attributes(context.user_scope.user.id, context.sport.id)
               )
    end

    test "fetch_all!/2 returns all teams", context do
      TeamsFixtures.add_teams(context.super_admin_scope, context.sport.id)
      assert length(Teams.fetch_all(context.super_admin_scope)) == 3
      assert length(Teams.fetch_all(context.admin_scope)) == 3
      assert length(Teams.fetch_all(context.user_scope)) == 0
    end

    test "update_team/3 with valid data updates the team", context do
      team = TeamsFixtures.add_team(context.super_admin_scope, context.sport.id)

      update_attrs = %{
        name: "some updated name",
        about: "some updated description"
      }

      assert {:ok, %Team{} = team} =
               Teams.update_team(context.super_admin_scope, team, update_attrs)

      assert team.name == "some updated name"
      assert team.about == "some updated description"
    end

    test "update_team/3 with invalid scope raises", context do
      team = TeamsFixtures.add_team(context.super_admin_scope, context.sport.id)

      assert {:error, :unauthorized} = Teams.update_team(context.admin_scope, team, %{})
    end

    test "update_team/3 with invalid data returns error changeset", context do
      team = TeamsFixtures.add_team(context.super_admin_scope, context.sport.id)

      assert {:error, %Ecto.Changeset{}} =
               Teams.update_team(
                 context.super_admin_scope,
                 team,
                 TeamsFixtures.get_invalid_attributes()
               )
    end

    test "delete_team/2 deletes the team", context do
      team = TeamsFixtures.add_team(context.super_admin_scope, context.sport.id)
      assert {:ok, %Team{}} = Teams.delete_team(context.super_admin_scope, team)
      assert [] == Teams.fetch_all(context.super_admin_scope)

      soft_deleted_team =
        from(d_team in Team, where: d_team.id == ^team.id) |> Repo.one()

      assert is_nil(soft_deleted_team.deleted_at) == false
    end

    test "delete_team/2 with invalid scope raises", context do
      team = TeamsFixtures.add_team(context.super_admin_scope, context.sport.id)
      assert {:error, :unauthorized} = Teams.delete_team(context.admin_scope, team)
    end

    test "delete_many_by_sport_id/1 deletes teams by sport id", context do
      TeamsFixtures.add_teams(context.super_admin_scope, context.sport.id)

      assert :ok = Teams.delete_many_by_sport_id(context.sport.id)
      assert [] == Teams.fetch_all(context.super_admin_scope)
    end

    test "delete_many_by_sport_id/1 delete none if no team with sport id exists", context do
      TeamsFixtures.add_teams(context.super_admin_scope, context.sport.id)

      assert :ok = Teams.delete_many_by_sport_id(32_123_383_131_313_401)
      assert 3 == length(Teams.fetch_all(context.super_admin_scope))
    end
  end
end
