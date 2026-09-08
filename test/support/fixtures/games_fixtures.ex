defmodule BetPeak.GamesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BetPeak.Games` context.
  """

  @doc """
  Generate a game.
  """
  def game_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        away_odds: "120.5",
        draw_odds: "120.5",
        home_odds: "120.5",
        result: "some result",
        starts_at: ~U[2026-09-06 13:59:00Z],
        status: "some status"
      })

    {:ok, game} = BetPeak.Games.create_game(scope, attrs)
    game
  end
end
