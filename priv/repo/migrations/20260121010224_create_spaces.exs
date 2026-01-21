defmodule ExDesk.Repo.Migrations.CreateSpaces do
  use Ecto.Migration

  def change do
    create table(:spaces) do
      add :name, :string, null: false
      add :key, :string, null: false
      add :description, :text
      add :color, :string, default: "#3B82F6"
      add :icon, :string, default: "hero-rectangle-stack"
      add :template, :string, null: false

      add :organization_id, references(:organizations, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:spaces, [:key])
    create index(:spaces, [:organization_id])

    alter table(:tickets) do
      add :space_id, references(:spaces, on_delete: :nilify_all)
    end

    create index(:tickets, [:space_id])
  end
end
