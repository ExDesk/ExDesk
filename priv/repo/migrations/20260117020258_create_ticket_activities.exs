defmodule ExDesk.Repo.Migrations.CreateTicketActivities do
  use Ecto.Migration

  def change do
    create table(:ticket_activities) do
      add :ticket_id, references(:tickets, on_delete: :delete_all), null: false
      add :actor_id, references(:users, on_delete: :nilify_all)
      add :action, :string, null: false
      add :field, :string
      add :old_value, :map
      add :new_value, :map

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:ticket_activities, [:ticket_id])
    create index(:ticket_activities, [:actor_id])
  end
end
