defmodule BetPeak.Repo.Migrations.CreateRoleInheritsTable do
  use Ecto.Migration

  def change do
    create table(:role_inherits) do
      add :parent_role_id, references(:roles, on_delete: :delete_all), null: false
      add :child_role_id, references(:roles, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:role_inherits, [:parent_role_id])
    create index(:role_inherits, [:child_role_id])

    create unique_index(:role_inherits, [:parent_role_id, :child_role_id])
  end
end
