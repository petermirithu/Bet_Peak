defmodule BetPeak.Repo.Migrations.CreateResourceTable do
  use Ecto.Migration

  def change do
    create table(:resources) do
      add :name, :string, null: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:resources, [:name])
  end
end
