defmodule ExDesk.Repo.Migrations.AddCreatedByToSpaces do
  use Ecto.Migration

  def change do
    alter table(:spaces) do
      add :created_by_id, references(:users, on_delete: :nilify_all)
    end

    create index(:spaces, [:created_by_id])
  end
end
