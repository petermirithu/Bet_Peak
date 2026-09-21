defmodule BetPeak.GamesTest do
  use BetPeak.DataCase

  describe "games" do
    alias BetPeak.Games
    alias BetPeak.Games.Game

    import BetPeak.AccountsFixtures,
      only: [
        user_scope_fixture: 0,
        super_admin_scope_fixture: 0,
        admin_scope_fixture: 0
      ]

    alias BetPeak.GamesFixtures
    alias BetPeak.AccessControlFixtures
    alias BetPeak.TeamsFixtures

    setup do
      AccessControlFixtures.setup_roles()
      super_admin_scope = super_admin_scope_fixture()

      sport = TeamsFixtures.create_sport(super_admin_scope.user.id)

      %{
        super_admin_scope: super_admin_scope,
        admin_scope: admin_scope_fixture(),
        user_scope: user_scope_fixture(),
        teams: TeamsFixtures.add_teams(super_admin_scope, sport.id)
      }
    end

    test "change_game_creation/2 returns a game changeset", context do
      game =
        GamesFixtures.add_game(
          context.super_admin_scope,
          Enum.at(context.teams, 0).id,
          Enum.at(context.teams, 1).id
        )

      assert %Ecto.Changeset{} =
               Games.change_game_creation(
                 game,
                 %{status: :live}
               )
    end

    test "validate_starts_at_in_future with bad start time should throw error", context do
      game =
        GamesFixtures.add_game(
          context.super_admin_scope,
          Enum.at(context.teams, 0).id,
          Enum.at(context.teams, 1).id
        )

      changeset =
        Games.change_game_creation(
          game,
          %{starts_at: DateTime.utc_now() |> DateTime.add(-1)}
        )

      assert hd(changeset.errors) == {:starts_at, {"must be in the future", []}}
    end

    test "validate_home_away_team where home team and away team can not be same", context do
      game =
        GamesFixtures.add_game(
          context.super_admin_scope,
          Enum.at(context.teams, 0).id,
          Enum.at(context.teams, 1).id
        )

      changeset =
        Games.change_game_creation(
          game,
          %{away_team_id: Enum.at(context.teams, 0).id}
        )

      assert hd(changeset.errors) ==
               {:away_team_id, {"Home team and away team cannot be the same team.", []}}
    end

    test "save_game/2 with valid data creates a game", context do
      valid_attr =
        GamesFixtures.get_valid_attributes(
          context.super_admin_scope.user.id,
          Enum.at(context.teams, 0).id,
          Enum.at(context.teams, 1).id
        )

      assert {:ok, %Game{} = game} =
               Games.save_game(
                 context.super_admin_scope,
                 valid_attr
               )

      assert game.result == valid_attr.result
      assert game.status == valid_attr.status
      assert game.home_odds == valid_attr.home_odds
      assert game.user_id == context.super_admin_scope.user.id
    end

    test "save_game/2 with invalid data returns error changeset", context do
      assert {:error, %Ecto.Changeset{}} =
               Games.save_game(
                 context.super_admin_scope,
                 GamesFixtures.get_invalid_attributes()
               )
    end

    test "save_game/2 with valid data but admin tries to create a game", context do
      assert {:error, :unauthorized} =
               Games.save_game(
                 context.admin_scope,
                 GamesFixtures.get_valid_attributes(
                   context.admin_scope.user.id,
                   Enum.at(context.teams, 0).id,
                   Enum.at(context.teams, 1).id
                 )
               )
    end

    test "save_game/2 with valid data but user tries to create a game", context do
      assert {:error, :unauthorized} =
               Games.save_game(
                 context.user_scope,
                 GamesFixtures.get_valid_attributes(
                   context.user_scope.user.id,
                   Enum.at(context.teams, 0).id,
                   Enum.at(context.teams, 1).id
                 )
               )
    end

    test "fetch_all!/2 returns all games", context do
      GamesFixtures.add_game(
        context.super_admin_scope,
        Enum.at(context.teams, 0).id,
        Enum.at(context.teams, 1).id
      )

      GamesFixtures.add_game(
        context.super_admin_scope,
        Enum.at(context.teams, 1).id,
        Enum.at(context.teams, 2).id
      )

      GamesFixtures.add_game(
        context.super_admin_scope,
        Enum.at(context.teams, 2).id,
        Enum.at(context.teams, 1).id
      )

      assert length(Games.fetch_all(context.super_admin_scope)) == 3
      assert length(Games.fetch_all(context.admin_scope)) == 3
      assert length(Games.fetch_all(context.user_scope)) == 3
    end

    test "fetch_active!/1 returns all active games", context do
      GamesFixtures.add_game(
        context.super_admin_scope,
        Enum.at(context.teams, 0).id,
        Enum.at(context.teams, 1).id
      )

      GamesFixtures.add_game(
        context.super_admin_scope,
        Enum.at(context.teams, 1).id,
        Enum.at(context.teams, 2).id,
        :live
      )

      GamesFixtures.add_game(
        context.super_admin_scope,
        Enum.at(context.teams, 2).id,
        Enum.at(context.teams, 1).id,
        :cancelled
      )

      assert length(Games.fetch_active(context.super_admin_scope)) == 2
      assert length(Games.fetch_active(context.admin_scope)) == 2
      assert length(Games.fetch_active(context.user_scope)) == 2
    end

    test "get_game_for_bets/1 gets one game by id", context do
      GamesFixtures.add_game(
        context.super_admin_scope,
        Enum.at(context.teams, 0).id,
        Enum.at(context.teams, 1).id
      )

      game =
        GamesFixtures.add_game(
          context.super_admin_scope,
          Enum.at(context.teams, 1).id,
          Enum.at(context.teams, 2).id,
          :live
        )

      GamesFixtures.add_game(
        context.super_admin_scope,
        Enum.at(context.teams, 2).id,
        Enum.at(context.teams, 1).id,
        :cancelled
      )

      assert game.id == Games.get_game_for_bets(game.id).id
    end

    test "update_game/3 with valid data updates the game", context do
      game =
        GamesFixtures.add_game(
          context.super_admin_scope,
          Enum.at(context.teams, 0).id,
          Enum.at(context.teams, 1).id
        )

      update_attrs = %{
        status: :finished,
        result: :away
      }

      assert {:ok, %Game{} = game} =
               Games.update_game(context.super_admin_scope, game, update_attrs)

      assert game.status == update_attrs.status
      assert game.result == update_attrs.result
    end

    test "update_game/3 but finished game must have result value not :pending ", context do
      game =
        GamesFixtures.add_game(
          context.super_admin_scope,
          Enum.at(context.teams, 0).id,
          Enum.at(context.teams, 1).id
        )

      update_attrs = %{
        status: :finished,
        result: :pending
      }

      assert {:error, %Ecto.Changeset{}} =
               Games.update_game(context.super_admin_scope, game, update_attrs)
    end

    test "update_game/3 with invalid scope raises", context do
      game =
        GamesFixtures.add_game(
          context.super_admin_scope,
          Enum.at(context.teams, 0).id,
          Enum.at(context.teams, 1).id
        )

      assert {:error, :unauthorized} = Games.update_game(context.admin_scope, game, %{})
    end

    test "update_game/3 with invalid data returns error changeset", context do
      game =
        GamesFixtures.add_game(
          context.super_admin_scope,
          Enum.at(context.teams, 0).id,
          Enum.at(context.teams, 1).id
        )

      assert {:error, %Ecto.Changeset{}} =
               Games.update_game(
                 context.super_admin_scope,
                 game,
                 GamesFixtures.get_invalid_attributes()
               )
    end

    test "delete_game/2 deletes the game", context do
      game =
        GamesFixtures.add_game(
          context.super_admin_scope,
          Enum.at(context.teams, 0).id,
          Enum.at(context.teams, 1).id
        )

      assert {:ok, %Game{}} = Games.delete_game(context.super_admin_scope, game)
      assert [] == Games.fetch_all(context.super_admin_scope)

      soft_deleted_game =
        from(d_game in Game, where: d_game.id == ^game.id) |> Repo.one()

      assert is_nil(soft_deleted_game.deleted_at) == false
    end

    test "delete_game/2 with invalid scope raises", context do
      game =
        GamesFixtures.add_game(
          context.super_admin_scope,
          Enum.at(context.teams, 0).id,
          Enum.at(context.teams, 1).id
        )

      assert {:error, :unauthorized} = Games.delete_game(context.admin_scope, game)
    end

    test "delete_many_by_team_id/1 deletes games by team id", context do
      GamesFixtures.add_game(
        context.super_admin_scope,
        Enum.at(context.teams, 0).id,
        Enum.at(context.teams, 1).id
      )

      GamesFixtures.add_game(
        context.super_admin_scope,
        Enum.at(context.teams, 1).id,
        Enum.at(context.teams, 2).id
      )

      GamesFixtures.add_game(
        context.super_admin_scope,
        Enum.at(context.teams, 1).id,
        Enum.at(context.teams, 0).id
      )

      assert :ok = Games.delete_many_by_team_id(Enum.at(context.teams, 2).id)
      assert 2 == length(Games.fetch_all(context.super_admin_scope))
    end

    test "delete_many_by_sport_id/1 delete none if no game with team id exists", context do
      GamesFixtures.add_game(
        context.super_admin_scope,
        Enum.at(context.teams, 1).id,
        Enum.at(context.teams, 0).id
      )

      assert :ok = Games.delete_many_by_team_id(11_212_119_1_312)
      assert 1 == length(Games.fetch_all(context.super_admin_scope))
    end
  end
end
