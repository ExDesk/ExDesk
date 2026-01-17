defmodule ExDesk.Repo.Migrations.CreateTicketComments do
  use Ecto.Migration

  def change do
    create table(:ticket_comments) do
      add :ticket_id, references(:tickets, on_delete: :delete_all), null: false
      add :author_id, references(:users, on_delete: :nilify_all), null: false
      add :body, :text, null: false
      add :is_public, :boolean, default: true

      timestamps(type: :utc_datetime)
    end

    create index(:ticket_comments, [:ticket_id])
    create index(:ticket_comments, [:author_id])
  end
end
