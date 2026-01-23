defmodule ExDesk.Support.Ticket do
  @moduledoc """
  Schema for support tickets.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias ExDesk.Accounts.User
  alias ExDesk.Support.{Group, Space, TicketComment, TicketActivity}

  schema "tickets" do
    field :subject, :string
    field :description, :string

    field :rank, :integer

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
    belongs_to :space, Space

    belongs_to :parent, __MODULE__
    has_many :children, __MODULE__, foreign_key: :parent_id

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
    |> foreign_key_constraint(:parent_id)
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
    |> foreign_key_constraint(:parent_id)
  end

  @doc """
  Programmatically associates this ticket to a parent ticket.

  This is intentionally *not* part of the public create/update casts to avoid
  accepting `parent_id` from user input.
  """
  def set_parent(%Ecto.Changeset{} = changeset, nil) do
    changeset
    |> put_change(:parent_id, nil)
  end

  def set_parent(%Ecto.Changeset{} = changeset, %__MODULE__{id: parent_id}) when is_integer(parent_id) do
    set_parent(changeset, parent_id)
  end

  def set_parent(%Ecto.Changeset{} = changeset, parent_id) when is_integer(parent_id) do
    changeset
    |> put_change(:parent_id, parent_id)
    |> validate_not_self_parent()
    |> foreign_key_constraint(:parent_id)
  end

  defp validate_not_self_parent(%Ecto.Changeset{} = changeset) do
    parent_id = get_field(changeset, :parent_id)
    id = get_field(changeset, :id)

    if is_integer(parent_id) and is_integer(id) and parent_id == id do
      add_error(changeset, :parent_id, "cannot reference itself")
    else
      changeset
    end
  end
end
