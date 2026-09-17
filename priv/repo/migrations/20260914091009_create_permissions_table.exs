defmodule BetPeak.Repo.Migrations.CreatePermissionsTable do
  use Ecto.Migration

  def change do
    create table(:permissions) do
      add :action, :string, null: false
      add :resource_id, references(:resources, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:permissions, [:action])
    create index(:permissions, [:resource_id])

    create unique_index(:permissions, [:action, :resource_id])
  end
end
