defmodule ExDesk.Repo.Migrations.CreateTickets do
  use Ecto.Migration

  def change do
    create table(:tickets) do
      add :subject, :string, null: false
      add :description, :text
      add :status, :string, default: "open", null: false
      add :priority, :string, default: "normal", null: false
      add :channel, :string, default: "web"
      add :requester_id, references(:users, on_delete: :nilify_all), null: false
      add :assignee_id, references(:users, on_delete: :nilify_all)
      add :group_id, references(:groups, on_delete: :nilify_all)
      add :due_at, :utc_datetime
      add :first_response_at, :utc_datetime
      add :solved_at, :utc_datetime
      add :closed_at, :utc_datetime
      add :tags, {:array, :string}, default: []
      add :custom_fields, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:tickets, [:requester_id])
    create index(:tickets, [:assignee_id])
    create index(:tickets, [:group_id])
    create index(:tickets, [:status])
    create index(:tickets, [:priority])
  end
end
