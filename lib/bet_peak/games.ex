defmodule BetPeak.Games do
  import Ecto.Query, warn: false
  alias BetPeak.Repo

  alias BetPeak.Games.Game
  alias BetPeak.Accounts.Scope

  def fetch_all() do
    Game
    |> Repo.all()
    |> Repo.preload(:home_team)
    |> Repo.preload(:away_team)
  end

  def get_game(%Scope{} = scope, id) do
    Repo.get_by!(Game, id: id, user_id: scope.user.id)
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
    game
    |> Game.changeset(attrs, [])
    |> Repo.update()
  end

  def delete_game(game) do
    Repo.delete(game)
  end
end
