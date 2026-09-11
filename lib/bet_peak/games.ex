defmodule BetPeak.Games do
  import Ecto.Query, warn: false
  alias BetPeak.Repo

  alias BetPeak.Games.Game
  alias BetPeak.Bets
  alias BetPeak.Workers

  def fetch_all() do
    from(game in Game, where: is_nil(game.deleted_at))
    |> Repo.all()
    |> Repo.preload(:home_team)
    |> Repo.preload(:away_team)
  end

  def fetch_active() do
    from(game in Game, where: is_nil(game.deleted_at) and game.status in [:scheduled, :live])
    |> Repo.all()
    |> Repo.preload(:home_team)
    |> Repo.preload(:away_team)
  end

  def get_game(id) do
    from(
      game in Game,
      where: is_nil(game.deleted_at) and game.id == ^id,
      limit: 1
    )
    |> Repo.one()
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
    game
    |> Ecto.Changeset.change(%{deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> Repo.update()
    |> Workers.SoftDelete.delete_children_records("bets")
  end

  def delete_games_by_team_id(team_id) do
    query =
      from(game in Game,
        where:
          (game.home_team_id == ^team_id or game.away_team_id == ^team_id) and
            is_nil(game.deleted_at)
      )

    query
    |> Repo.all()
    |> soft_delete_games(query)
    |> Enum.each(fn game ->
      Workers.SoftDelete.delete_children_records({:ok, game}, "bets")
    end)
  end

  defp soft_delete_games(games, query) do
    Repo.update_all(query, set: [deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)])
    games
  end
end
