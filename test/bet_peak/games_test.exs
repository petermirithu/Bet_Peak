defmodule BetPeak.GamesTest do
  use BetPeak.DataCase

  alias BetPeak.Games

  describe "games" do
    alias BetPeak.Games.Game

    import BetPeak.AccountsFixtures, only: [user_scope_fixture: 0]
    import BetPeak.GamesFixtures

    @invalid_attrs %{status: nil, result: nil, starts_at: nil, home_odds: nil, away_odds: nil, draw_odds: nil}

    test "list_games/1 returns all scoped games" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      game = game_fixture(scope)
      other_game = game_fixture(other_scope)
      assert Games.list_games(scope) == [game]
      assert Games.list_games(other_scope) == [other_game]
    end

    test "get_game!/2 returns the game with given id" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      other_scope = user_scope_fixture()
      assert Games.get_game!(scope, game.id) == game
      assert_raise Ecto.NoResultsError, fn -> Games.get_game!(other_scope, game.id) end
    end

    test "create_game/2 with valid data creates a game" do
      valid_attrs = %{status: "some status", result: "some result", starts_at: ~U[2026-09-06 13:59:00Z], home_odds: "120.5", away_odds: "120.5", draw_odds: "120.5"}
      scope = user_scope_fixture()

      assert {:ok, %Game{} = game} = Games.create_game(scope, valid_attrs)
      assert game.status == "some status"
      assert game.result == "some result"
      assert game.starts_at == ~U[2026-09-06 13:59:00Z]
      assert game.home_odds == Decimal.new("120.5")
      assert game.away_odds == Decimal.new("120.5")
      assert game.draw_odds == Decimal.new("120.5")
      assert game.user_id == scope.user.id
    end

    test "create_game/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Games.create_game(scope, @invalid_attrs)
    end

    test "update_game/3 with valid data updates the game" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      update_attrs = %{status: "some updated status", result: "some updated result", starts_at: ~U[2026-09-07 13:59:00Z], home_odds: "456.7", away_odds: "456.7", draw_odds: "456.7"}

      assert {:ok, %Game{} = game} = Games.update_game(scope, game, update_attrs)
      assert game.status == "some updated status"
      assert game.result == "some updated result"
      assert game.starts_at == ~U[2026-09-07 13:59:00Z]
      assert game.home_odds == Decimal.new("456.7")
      assert game.away_odds == Decimal.new("456.7")
      assert game.draw_odds == Decimal.new("456.7")
    end

    test "update_game/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      game = game_fixture(scope)

      assert_raise MatchError, fn ->
        Games.update_game(other_scope, game, %{})
      end
    end

    test "update_game/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Games.update_game(scope, game, @invalid_attrs)
      assert game == Games.get_game!(scope, game.id)
    end

    test "delete_game/2 deletes the game" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      assert {:ok, %Game{}} = Games.delete_game(scope, game)
      assert_raise Ecto.NoResultsError, fn -> Games.get_game!(scope, game.id) end
    end

    test "delete_game/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      game = game_fixture(scope)
      assert_raise MatchError, fn -> Games.delete_game(other_scope, game) end
    end

    test "change_game/2 returns a game changeset" do
      scope = user_scope_fixture()
      game = game_fixture(scope)
      assert %Ecto.Changeset{} = Games.change_game(scope, game)
    end
  end
end
