defmodule BetPeak.BetsTest do
  use BetPeak.DataCase

  alias BetPeak.Bets

  describe "bets" do
    alias BetPeak.Bets.Bet

    import BetPeak.AccountsFixtures, only: [user_scope_fixture: 0]
    import BetPeak.BetsFixtures

    @invalid_attrs %{status: nil, selection: nil, stake_amount: nil, odds_at_placement: nil, potential_payout: nil}

    test "list_bets/1 returns all scoped bets" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      bet = bet_fixture(scope)
      other_bet = bet_fixture(other_scope)
      assert Bets.list_bets(scope) == [bet]
      assert Bets.list_bets(other_scope) == [other_bet]
    end

    test "get_bet!/2 returns the bet with given id" do
      scope = user_scope_fixture()
      bet = bet_fixture(scope)
      other_scope = user_scope_fixture()
      assert Bets.get_bet!(scope, bet.id) == bet
      assert_raise Ecto.NoResultsError, fn -> Bets.get_bet!(other_scope, bet.id) end
    end

    test "create_bet/2 with valid data creates a bet" do
      valid_attrs = %{status: "some status", selection: "some selection", stake_amount: "120.5", odds_at_placement: "120.5", potential_payout: "120.5"}
      scope = user_scope_fixture()

      assert {:ok, %Bet{} = bet} = Bets.create_bet(scope, valid_attrs)
      assert bet.status == "some status"
      assert bet.selection == "some selection"
      assert bet.stake_amount == Decimal.new("120.5")
      assert bet.odds_at_placement == Decimal.new("120.5")
      assert bet.potential_payout == Decimal.new("120.5")
      assert bet.user_id == scope.user.id
    end

    test "create_bet/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Bets.create_bet(scope, @invalid_attrs)
    end

    test "update_bet/3 with valid data updates the bet" do
      scope = user_scope_fixture()
      bet = bet_fixture(scope)
      update_attrs = %{status: "some updated status", selection: "some updated selection", stake_amount: "456.7", odds_at_placement: "456.7", potential_payout: "456.7"}

      assert {:ok, %Bet{} = bet} = Bets.update_bet(scope, bet, update_attrs)
      assert bet.status == "some updated status"
      assert bet.selection == "some updated selection"
      assert bet.stake_amount == Decimal.new("456.7")
      assert bet.odds_at_placement == Decimal.new("456.7")
      assert bet.potential_payout == Decimal.new("456.7")
    end

    test "update_bet/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      bet = bet_fixture(scope)

      assert_raise MatchError, fn ->
        Bets.update_bet(other_scope, bet, %{})
      end
    end

    test "update_bet/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      bet = bet_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Bets.update_bet(scope, bet, @invalid_attrs)
      assert bet == Bets.get_bet!(scope, bet.id)
    end

    test "delete_bet/2 deletes the bet" do
      scope = user_scope_fixture()
      bet = bet_fixture(scope)
      assert {:ok, %Bet{}} = Bets.delete_bet(scope, bet)
      assert_raise Ecto.NoResultsError, fn -> Bets.get_bet!(scope, bet.id) end
    end

    test "delete_bet/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      bet = bet_fixture(scope)
      assert_raise MatchError, fn -> Bets.delete_bet(other_scope, bet) end
    end

    test "change_bet/2 returns a bet changeset" do
      scope = user_scope_fixture()
      bet = bet_fixture(scope)
      assert %Ecto.Changeset{} = Bets.change_bet(scope, bet)
    end
  end
end
