defmodule BetPeak.Games do
  import Ecto.Query, warn: false
  alias BetPeak.Repo

  alias BetPeak.Games.Game
  alias BetPeak.Bets

  def fetch_all() do
    Game
    |> Repo.all()
    |> Repo.preload(:home_team)
    |> Repo.preload(:away_team)
  end

  def fetch_active() do
    query = from game in Game, where: game.status in [:scheduled, :live]

    Repo.all(query)
    |> Repo.preload(:home_team)
    |> Repo.preload(:away_team)
  end

  def get_game(id) do
    Repo.get_by(Game, id: id)
  end

  def save_game(attrs) do
    %Game{}
    |> Game.changeset(attrs, [])
    |> Repo.insert()
  end

  def change_game_creation(game, attrs \\ %{}, opts \\ []) do
    Game.changeset(game, attrs, opts)
  end

  def update_game(game, attrs) do
    previous_status = game.status

    result =
      game
      |> Game.changeset(attrs, [])
      |> Repo.update()

    case result do
      {:ok, updated_game} ->
        if previous_status != :finished and updated_game.status == :finished do
          Bets.settle_game_bets(updated_game.id, updated_game.result)
        end

        result

      error ->
        error
    end
  end

  def delete_game(game) do
    Repo.delete(game)
  end
end
