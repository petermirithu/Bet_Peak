defmodule BetPeak.Repo.Migrations.ModifyUniqueIndexOnUsers do
  use Ecto.Migration

  def change do
    drop unique_index(:users, [:email])
    drop unique_index(:users, [:msisdn])

    create unique_index(:users, [:email], where: "deleted_at IS NULL")
    create unique_index(:users, [:msisdn], where: "deleted_at IS NULL")
  end
end
