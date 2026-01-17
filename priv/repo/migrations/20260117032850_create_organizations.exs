defmodule ExDesk.Repo.Migrations.CreateOrganizations do
  use Ecto.Migration

  def change do
    create table(:organizations) do
      add :name, :string, null: false
      add :domain, :string
      add :notes, :text

      add :phone, :string
      add :website, :string

      add :address, :string
      add :city, :string
      add :state, :string
      add :country, :string, default: "Brasil"
      add :postal_code, :string

      add :is_active, :boolean, default: true, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organizations, [:domain])
    create index(:organizations, [:name])
    create index(:organizations, [:is_active])

    alter table(:users) do
      add :organization_id, references(:organizations, on_delete: :nilify_all)
    end

    create index(:users, [:organization_id])
  end
end
