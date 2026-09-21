defmodule BetPeak.GamesFixtures do
  def get_valid_attributes(user_id, home_team_id, away_team_id) do
    %{
      starts_at: DateTime.utc_now() |> DateTime.add(1),
      status: :scheduled,
      home_odds: Decimal.new("2.1"),
      away_odds: Decimal.new("3.1"),
      draw_odds: Decimal.new("4.1"),
      result: :pending,
      user_id: user_id,
      home_team_id: home_team_id,
      away_team_id: away_team_id
    }
  end

  def get_invalid_attributes() do
    %{
      starts_at: nil,
      status: :scheduled,
      home_odds: 2.1,
      away_odds: 3.0,
      draw_odds: 4.1,
      result: :pending,
      user_id: nil,
      home_team_id: nil,
      away_team_id: nil
    }
  end

  def add_game(scope, home_team_id, away_team_id, status) do
    attrs =
      get_valid_attributes(scope.user.id, home_team_id, away_team_id) |> Map.put(:status, status)

    {:ok, game} =
      BetPeak.Games.save_game(scope, attrs)

    game
  end

  def add_game(scope, home_team_id, away_team_id) do
    {:ok, game} =
      BetPeak.Games.save_game(
        scope,
        get_valid_attributes(scope.user.id, home_team_id, away_team_id)
      )

    game
  end
end
