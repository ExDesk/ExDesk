defmodule ExDesk.Repo.Migrations.AddRankToTickets do
  use Ecto.Migration

  def change do
    alter table(:tickets) do
      add :rank, :integer
    end

    create index(:tickets, [:space_id, :rank])
    create index(:tickets, [:space_id, :status, :rank])
  end
end
