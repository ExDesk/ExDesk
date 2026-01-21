defmodule ExDesk.Support.Space do
  @moduledoc """
  Schema for Spaces - high-level containers for organizing tickets.
  Similar to Jira Spaces/Projects.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @templates [:kanban, :service_desk, :project]

  schema "spaces" do
    field :name, :string
    field :key, :string
    field :description, :string
    field :color, :string, default: "#3B82F6"
    field :icon, :string, default: "hero-rectangle-stack"
    field :template, Ecto.Enum, values: @templates

    belongs_to :organization, ExDesk.Organizations.Organization

    has_many :tickets, ExDesk.Support.Ticket

    timestamps(type: :utc_datetime)
  end

  @required_fields [:name, :key, :template]
  @optional_fields [:description, :color, :icon, :organization_id]

  @doc """
  Changeset for creating or updating a space.
  """
  def changeset(space, attrs) do
    space
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:key, max: 10)
    |> validate_format(:key, ~r/^[A-Z]+$/,
      message: "must be uppercase letters only (e.g., IT, HR, FAC)"
    )
    |> validate_length(:name, min: 2, max: 100)
    |> unique_constraint(:key)
    |> foreign_key_constraint(:organization_id)
  end

  @doc """
  Returns available templates for spaces.
  """
  def templates, do: @templates
end
