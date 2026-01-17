defmodule ExDesk.Repo.Migrations.CreateGroups do
  use Ecto.Migration

  def change do
    create table(:groups) do
      add :name, :string, null: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:groups, [:name])
  end
end
