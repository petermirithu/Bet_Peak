defmodule BetPeak.Sports do
  import Ecto.Query, warn: false

  alias BetPeak.Repo
  alias BetPeak.Sports.Sport
  alias BetPeak.Workers
  alias BetPeak.Accounts.Scope
  alias BetPeak.Authorization

  def fetch_all_active(%Scope{} = current_scope) do
    case Authorization.authorize!(current_scope, "Sports", "read") do
      :ok ->
        from(sport in Sport, where: is_nil(sport.deleted_at) and sport.active == true)
        |> Repo.all()

      :unauthorized ->
        []
    end
  end

  def fetch_all(%Scope{} = current_scope) do
    case Authorization.authorize!(current_scope, "Sports", "read") do
      :ok ->
        from(sport in Sport, where: is_nil(sport.deleted_at))
        |> Repo.all()

      :unauthorized ->
        []
    end
  end

  def save_sport(%Scope{} = current_scope, attrs) do
    case Authorization.authorize!(current_scope, "Sports", "create") do
      :ok ->
        %Sport{}
        |> Sport.changeset(attrs, [])
        |> Repo.insert()

      :unauthorized ->
        {:error, :unauthorized}
    end
  end

  def change_sport_creation(sport, attrs \\ %{}, opts \\ []) do
    Sport.changeset(sport, attrs, opts)
  end

  def update_sport(%Scope{} = current_scope, sport, attrs) do
    case Authorization.authorize!(current_scope, "Sports", "update") do
      :ok ->
        sport
        |> Sport.changeset(attrs, [])
        |> Repo.update()

      :unauthorized ->
        {:error, :unauthorized}
    end
  end

  def delete_sport(%Scope{} = current_scope, sport) do
    case Authorization.authorize!(current_scope, "Sports", "delete") do
      :ok ->
        sport
        |> Ecto.Changeset.change(%{deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)})
        |> Repo.update()
        |> Workers.SoftDelete.delete_children_records("sport_teams")

      :unauthorized ->
        {:error, :unauthorized}
    end
  end
end
