defmodule BetPeak.Repo.Migrations.ModifyUniqueIndexOnTeams do
  use Ecto.Migration

  def change do
    drop unique_index(:teams, [:short_form])
    drop unique_index(:teams, [:name])

    create unique_index(:teams, [:short_form], where: "deleted_at IS NULL")
    create unique_index(:teams, [:name], where: "deleted_at IS NULL")
  end
end
