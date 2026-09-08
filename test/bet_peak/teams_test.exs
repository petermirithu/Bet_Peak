defmodule BetPeak.TeamsTest do
  use BetPeak.DataCase

  alias BetPeak.Teams

  describe "teams" do
    alias BetPeak.Teams.Team

    import BetPeak.AccountsFixtures, only: [user_scope_fixture: 0]
    import BetPeak.TeamsFixtures

    @invalid_attrs %{name: nil, short_form: nil}

    test "list_teams/1 returns all scoped teams" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      team = team_fixture(scope)
      other_team = team_fixture(other_scope)
      assert Teams.list_teams(scope) == [team]
      assert Teams.list_teams(other_scope) == [other_team]
    end

    test "get_team!/2 returns the team with given id" do
      scope = user_scope_fixture()
      team = team_fixture(scope)
      other_scope = user_scope_fixture()
      assert Teams.get_team!(scope, team.id) == team
      assert_raise Ecto.NoResultsError, fn -> Teams.get_team!(other_scope, team.id) end
    end

    test "create_team/2 with valid data creates a team" do
      valid_attrs = %{name: "some name", short_form: "some short_form"}
      scope = user_scope_fixture()

      assert {:ok, %Team{} = team} = Teams.create_team(scope, valid_attrs)
      assert team.name == "some name"
      assert team.short_form == "some short_form"
      assert team.user_id == scope.user.id
    end

    test "create_team/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Teams.create_team(scope, @invalid_attrs)
    end

    test "update_team/3 with valid data updates the team" do
      scope = user_scope_fixture()
      team = team_fixture(scope)
      update_attrs = %{name: "some updated name", short_form: "some updated short_form"}

      assert {:ok, %Team{} = team} = Teams.update_team(scope, team, update_attrs)
      assert team.name == "some updated name"
      assert team.short_form == "some updated short_form"
    end

    test "update_team/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      team = team_fixture(scope)

      assert_raise MatchError, fn ->
        Teams.update_team(other_scope, team, %{})
      end
    end

    test "update_team/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      team = team_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Teams.update_team(scope, team, @invalid_attrs)
      assert team == Teams.get_team!(scope, team.id)
    end

    test "delete_team/2 deletes the team" do
      scope = user_scope_fixture()
      team = team_fixture(scope)
      assert {:ok, %Team{}} = Teams.delete_team(scope, team)
      assert_raise Ecto.NoResultsError, fn -> Teams.get_team!(scope, team.id) end
    end

    test "delete_team/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      team = team_fixture(scope)
      assert_raise MatchError, fn -> Teams.delete_team(other_scope, team) end
    end

    test "change_team/2 returns a team changeset" do
      scope = user_scope_fixture()
      team = team_fixture(scope)
      assert %Ecto.Changeset{} = Teams.change_team(scope, team)
    end
  end
end
