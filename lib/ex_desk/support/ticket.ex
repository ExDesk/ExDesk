defmodule ExDesk.Support.Ticket do
  use Ecto.Schema
  import Ecto.Changeset

  alias ExDesk.Accounts.User
  alias ExDesk.Support.{Group, TicketComment, TicketActivity}

  schema "tickets" do
    field :subject, :string
    field :description, :string

    field :status, Ecto.Enum,
      values: [:open, :pending, :on_hold, :solved, :closed],
      default: :open

    field :priority, Ecto.Enum, values: [:low, :normal, :high, :urgent], default: :normal
    field :channel, Ecto.Enum, values: [:email, :web, :phone, :chat, :api], default: :web
    field :due_at, :utc_datetime
    field :first_response_at, :utc_datetime
    field :solved_at, :utc_datetime
    field :closed_at, :utc_datetime
    field :tags, {:array, :string}, default: []
    field :custom_fields, :map, default: %{}

    belongs_to :requester, User
    belongs_to :assignee, User
    belongs_to :group, Group

    has_many :comments, TicketComment
    has_many :activities, TicketActivity

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating a new ticket.
  """
  def create_changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [
      :subject,
      :description,
      :status,
      :priority,
      :channel,
      :requester_id,
      :assignee_id,
      :group_id,
      :due_at,
      :tags,
      :custom_fields
    ])
    |> validate_required([:subject, :requester_id])
    |> foreign_key_constraint(:requester_id)
    |> foreign_key_constraint(:assignee_id)
    |> foreign_key_constraint(:group_id)
  end

  @doc """
  Changeset for updating an existing ticket.
  """
  def update_changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [
      :subject,
      :description,
      :status,
      :priority,
      :assignee_id,
      :group_id,
      :due_at,
      :first_response_at,
      :solved_at,
      :closed_at,
      :tags,
      :custom_fields
    ])
    |> validate_required([:subject])
    |> foreign_key_constraint(:assignee_id)
    |> foreign_key_constraint(:group_id)
  end
end
