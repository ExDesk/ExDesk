defmodule ExDesk.Repo.Migrations.AddParentIdToTickets do
  use Ecto.Migration

  def change do
    alter table(:tickets) do
      add :parent_id, references(:tickets, on_delete: :nilify_all)
    end

    create index(:tickets, [:parent_id])
  end
end
