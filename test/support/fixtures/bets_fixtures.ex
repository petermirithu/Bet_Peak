defmodule BetPeak.BetsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BetPeak.Bets` context.
  """

  @doc """
  Generate a bet.
  """
  def bet_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        odds_at_placement: "120.5",
        potential_payout: "120.5",
        selection: "some selection",
        stake_amount: "120.5",
        status: "some status"
      })

    {:ok, bet} = BetPeak.Bets.create_bet(scope, attrs)
    bet
  end
end
