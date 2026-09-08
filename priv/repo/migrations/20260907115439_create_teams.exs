defmodule BetPeak.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :name, :string
      add :short_form, :string
      add :about, :string
      add :user_id, references(:users, on_delete: :delete_all)
      add :sport_id, references(:sports, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:teams, [:user_id])
    create index(:teams, [:sport_id])

    create unique_index(:teams, [:short_form])
    create unique_index(:teams, [:name])
  end
end
