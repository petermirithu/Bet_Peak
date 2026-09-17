defmodule BetPeak.Repo.Migrations.SportsRemoveSlug do
  use Ecto.Migration

  def change do
    alter table(:sports) do
      remove :slug
    end
  end
end
