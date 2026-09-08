defmodule BetPeak.Repo.Migrations.CreateSports do
  use Ecto.Migration

  def change do
    create table(:sports) do
      add :name, :string
      add :description, :string
      add :active, :boolean, default: true, null: false
      add :slug, :string
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:sports, [:user_id])

    create unique_index(:sports, [:slug])
    create unique_index(:sports, [:name])
  end
end
