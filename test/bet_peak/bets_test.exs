defmodule BetPeak.BetsTest do
  use BetPeak.DataCase

  describe "bets" do
    alias BetPeak.Bets
    alias BetPeak.Bets.Bet

    import BetPeak.AccountsFixtures,
      only: [
        user_scope_fixture: 0,
        super_admin_scope_fixture: 0,
        admin_scope_fixture: 0
      ]

    alias BetPeak.BetsFixtures
    alias BetPeak.AccessControlFixtures
    alias BetPeak.GamesFixtures
    alias BetPeak.TeamsFixtures

    setup do
      AccessControlFixtures.setup_roles()
      super_admin_scope = super_admin_scope_fixture()

      sport = TeamsFixtures.create_sport(super_admin_scope.user.id)
      teams = TeamsFixtures.add_teams(super_admin_scope, sport.id)

      %{
        super_admin_scope: super_admin_scope,
        admin_scope: admin_scope_fixture(),
        user_scope: user_scope_fixture(),
        game:
          GamesFixtures.add_game(
            super_admin_scope,
            Enum.at(teams, 0).id,
            Enum.at(teams, 1).id
          )
      }
    end

    test "change_bet/2 returns a bet changeset", context do
      bet = BetsFixtures.add_bet(context.super_admin_scope, context.game.id)

      assert %Ecto.Changeset{} =
               Bets.change_bet_creation(
                 bet,
                 %{selection: :away}
               )
    end

    test "validate stake amount to be more than 100", context do
      bet = BetsFixtures.add_bet(context.super_admin_scope, context.game.id)

      changeset =
        Bets.change_bet_creation(
          bet,
          %{stake_amount: Decimal.new("10.0")}
        )

      {:stake_amount, {message, _details}} = hd(changeset.errors)
      assert message == "must be greater than %{number}"
    end

    # test "validate add_odds_at_placement is being captured", context do
    #   bet = BetsFixtures.add_bet(context.super_admin_scope, context.game.id)

    #   changeset =
    #     Bets.change_bet_creation(
    #       bet,
    #       %{stake_amount: Decimal.new("200.0")}
    #     )

    #   IO.inspect(changeset.data)
    #   # {:stake_amount, {message, _details}} = hd(changeset.errors)
    #   assert changeset.data.odds_at_placement == "must be greater than %{number}"
    # end

    test "save_bet/2 with valid data creates a bet", context do
      valid_attr =
        BetsFixtures.get_valid_attributes(context.super_admin_scope.user.id, context.game.id)

      assert {:ok, %Bet{} = bet} =
               Bets.save_bet(
                 context.super_admin_scope,
                 valid_attr
               )

      assert bet.selection == valid_attr.selection
      assert bet.stake_amount == valid_attr.stake_amount
      assert bet.user_id == context.super_admin_scope.user.id
      assert bet.game_id == context.game.id
    end

    test "save_bet/2 with invalid data returns error changeset", context do
      assert {:error, %Ecto.Changeset{}} =
               Bets.save_bet(
                 context.super_admin_scope,
                 BetsFixtures.get_invalid_attributes()
               )
    end

    # test "save_bet/2 with valid data but user tries to create a bet", context do
    #   assert {:error, :unauthorized} =
    #            Bets.save_bet(
    #              context.user_scope,
    #              BetsFixtures.get_valid_attributes(context.user_scope.user.id)
    #            )
    # end

    # test "fetch_all_active/1 returns all active bets", context do
    #   BetsFixtures.add_bets(context.super_admin_scope)
    #   assert length(Bets.fetch_all_active(context.super_admin_scope)) == 2
    #   assert length(Bets.fetch_all_active(context.admin_scope)) == 2
    #   assert [] = Bets.fetch_all_active(context.user_scope)
    # end

    # test "fetch_all!/2 returns all active and inactive bets", context do
    #   BetsFixtures.add_bets(context.super_admin_scope)
    #   assert length(Bets.fetch_all(context.super_admin_scope)) == 3
    #   assert length(Bets.fetch_all(context.admin_scope)) == 3
    #   assert length(Bets.fetch_all(context.user_scope)) == 0
    # end

    # test "update_bet/3 with valid data updates the bet", context do
    #   bet = BetsFixtures.add_bet(context.super_admin_scope)

    #   update_attrs = %{
    #     active: false,
    #     name: "some updated name",
    #     description: "some updated description"
    #   }

    #   assert {:ok, %Bet{} = bet} =
    #            Bets.update_bet(context.super_admin_scope, bet, update_attrs)

    #   assert bet.active == false
    #   assert bet.name == "some updated name"
    #   assert bet.description == "some updated description"
    # end

    # test "update_bet/3 with invalid scope raises", context do
    #   bet = BetsFixtures.add_bet(context.super_admin_scope)

    #   assert {:error, :unauthorized} = Bets.update_bet(context.admin_scope, bet, %{})
    # end

    # test "update_bet/3 with invalid data returns error changeset", context do
    #   bet = BetsFixtures.add_bet(context.super_admin_scope)

    #   assert {:error, %Ecto.Changeset{}} =
    #            Bets.update_bet(
    #              context.super_admin_scope,
    #              bet,
    #              BetsFixtures.get_invalid_attributes(0)
    #            )
    # end

    # test "delete_bet/2 deletes the bet", context do
    #   bet = BetsFixtures.add_bet(context.super_admin_scope)
    #   assert {:ok, %Bet{}} = Bets.delete_bet(context.super_admin_scope, bet)
    #   assert [] == Bets.fetch_all_active(context.super_admin_scope)

    #   soft_deleted_bet =
    #     from(d_bet in Bet, where: d_bet.id == ^bet.id) |> Repo.one()

    #   assert is_nil(soft_deleted_bet.deleted_at) == false
    # end

    # test "delete_bet/2 with invalid scope raises", context do
    #   bet = BetsFixtures.add_bet(context.super_admin_scope)
    #   assert {:error, :unauthorized} = Bets.delete_bet(context.admin_scope, bet)
    # end
  end
end
