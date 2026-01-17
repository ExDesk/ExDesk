defmodule ExDesk.Support.TicketComment do
  use Ecto.Schema
  import Ecto.Changeset

  alias ExDesk.Accounts.User
  alias ExDesk.Support.Ticket

  schema "ticket_comments" do
    field :body, :string
    field :is_public, :boolean, default: true

    belongs_to :ticket, Ticket
    belongs_to :author, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:body, :is_public, :ticket_id, :author_id])
    |> validate_required([:body, :ticket_id, :author_id])
    |> foreign_key_constraint(:ticket_id)
    |> foreign_key_constraint(:author_id)
  end
end
