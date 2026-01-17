defmodule ExDesk.Repo.Migrations.EnhanceUsersTable do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :name, :string
      add :phone, :string
      add :avatar_url, :string
      add :is_active, :boolean, default: true, null: false
      add :last_sign_in_at, :utc_datetime
      add :time_zone, :string, default: "America/Sao_Paulo"
      add :locale, :string, default: "pt-BR"
      add :notes, :text
      add :employee_number, :string
      add :job_title, :string
      add :department, :string
    end

    create index(:users, [:employee_number])
    create index(:users, [:is_active])
  end
end
