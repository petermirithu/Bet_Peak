defmodule BetPeak.Repo.Migrations.ModifyUniqueIndexOnSports do
  use Ecto.Migration

  def change do
    drop unique_index(:sports, [:slug])
    drop unique_index(:sports, [:name])

    create unique_index(:sports, [:slug], where: "deleted_at IS NULL")
    create unique_index(:sports, [:name], where: "deleted_at IS NULL")
  end
end
