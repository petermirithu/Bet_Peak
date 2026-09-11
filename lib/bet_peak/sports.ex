defmodule BetPeak.Sports do
  import Ecto.Query, warn: false

  alias BetPeak.Repo
  alias BetPeak.Sports.Sport
  alias BetPeak.Workers

  def fetch_all() do
    from(sport in Sport, where: is_nil(sport.deleted_at))
    |> Repo.all()
  end

  def save_sport(attrs) do
    %Sport{}
    |> Sport.changeset(attrs, [])
    |> Repo.insert()
  end

  def change_sport_creation(sport, attrs \\ %{}, opts \\ []) do
    Sport.changeset(sport, attrs, opts)
  end

  def update_sport(sport, attrs) do
    sport
    |> Sport.changeset(attrs, [])
    |> Repo.update()
  end

  def delete_sport(sport) do
    sport
    |> Ecto.Changeset.change(%{deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> Repo.update()
    |> Workers.SoftDelete.delete_children_records("teams")
  end
end
