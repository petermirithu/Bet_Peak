defmodule BetPeak.Games do
  import Ecto.Query, warn: false
  alias BetPeak.Repo

  alias BetPeak.Games.Game
  alias BetPeak.Bets
  alias BetPeak.Workers
  alias BetPeak.Authorization
  alias BetPeak.Accounts.Scope

  def fetch_all(%Scope{} = current_scope) do
    case Authorization.authorize!(current_scope, "Games", "read") do
      :ok ->
        from(game in Game, where: is_nil(game.deleted_at))
        |> Repo.all()
        |> Repo.preload(:home_team)
        |> Repo.preload(:away_team)

      :unauthorized ->
        []
    end
  end

  def fetch_active(%Scope{} = current_scope) do
    case Authorization.authorize!(current_scope, "Games", "read") do
      :ok ->
        from(game in Game, where: is_nil(game.deleted_at) and game.status in [:scheduled, :live])
        |> Repo.all()
        |> Repo.preload(:home_team)
        |> Repo.preload(:away_team)

      :unauthorized ->
        []
    end
  end

  def get_game_for_bets(id) do
    # Private for bets
    from(
      game in Game,
      where: is_nil(game.deleted_at) and game.id == ^id,
      limit: 1
    )
    |> Repo.one()
  end

  def save_game(%Scope{} = current_scope, attrs) do
    case Authorization.authorize!(current_scope, "Games", "create") do
      :ok ->
        %Game{}
        |> Game.changeset(attrs, [])
        |> Repo.insert()

      :unauthorized ->
        {:error, :unauthorized}
    end
  end

  def change_game_creation(game, attrs \\ %{}, opts \\ []) do
    Game.changeset(game, attrs, opts)
  end

  def update_game(%Scope{} = current_scope, game, attrs) do
    case Authorization.authorize!(current_scope, "Games", "update") do
      :ok ->
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

      :unauthorized ->
        {:error, :unauthorized}
    end
  end

  def delete_game(%Scope{} = current_scope, game) do
    case Authorization.authorize!(current_scope, "Games", "delete") do
      :ok ->
        game
        |> Ecto.Changeset.change(%{deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)})
        |> Repo.update()
        |> Workers.SoftDelete.delete_children_records("game_bets")

      :unauthorized ->
        {:error, :unauthorized}
    end
  end

  def delete_many_by_team_id(team_id) do
    # Scope is already on delete team
    # Called when a team is deleted.
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
      Workers.SoftDelete.delete_children_records({:ok, game}, "game_bets")
    end)
  end

  defp soft_delete_games(games, query) do
    Repo.update_all(query, set: [deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)])
    games
  end
end
