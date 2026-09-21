defmodule BetPeak.BetsFixtures do
  def get_valid_attributes(user_id, game_id) do
    %{
      selection: Enum.random([:home, :draw, :away]),
      stake_amount: Decimal.new("200"),
      user_id: user_id,
      game_id: game_id
    }
  end

  def get_invalid_attributes() do
    %{
      selection: nil,
      stake_amount: Decimal.new("10"),
      user_id: nil,
      game_id: nil
    }
  end

  # def add_bets(scope) do
  #   valid_active_1 = get_valid_attributes(scope.user.id, game_id)
  #   valid_active_2 = get_valid_attributes(scope.user.id, game_id)
  #   valid_inactive_1 = get_valid_attributes(scope.user.id, game_id)

  #   BetPeak.Bets.save_bet(scope, valid_active_1)
  #   BetPeak.Bets.save_bet(scope, valid_active_2)
  #   BetPeak.Bets.save_bet(scope, valid_inactive_1)
  # end

  def add_bet(scope, game_id) do
    {:ok, bet} = BetPeak.Bets.save_bet(scope, get_valid_attributes(scope.user.id, game_id))
    bet
  end
end
