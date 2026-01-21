defmodule ExDesk.Support.TicketActivity do
  @moduledoc """
  Schema for tracking ticket activities/history.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias ExDesk.Accounts.User
  alias ExDesk.Support.Ticket

  @actions [
    :created,
    :status_changed,
    :priority_changed,
    :assigned,
    :unassigned,
    :group_changed,
    :commented,
    :tag_added,
    :tag_removed,
    :custom_field_changed
  ]

  schema "ticket_activities" do
    field :action, Ecto.Enum, values: @actions
    field :field, :string
    field :old_value, :map
    field :new_value, :map

    belongs_to :ticket, Ticket
    belongs_to :actor, User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc false
  def changeset(activity, attrs) do
    activity
    |> cast(attrs, [:action, :field, :old_value, :new_value, :ticket_id, :actor_id])
    |> validate_required([:action, :ticket_id])
    |> foreign_key_constraint(:ticket_id)
    |> foreign_key_constraint(:actor_id)
  end
end
