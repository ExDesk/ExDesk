defmodule ExDesk.Organizations.Organization do
  @moduledoc """
  Schema for organizations/companies.
  Similar to Organizations in Zendesk and Companies in Snipe-IT.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "organizations" do
    field :name, :string
    field :domain, :string
    field :notes, :string

    field :phone, :string
    field :website, :string

    field :address, :string
    field :city, :string
    field :state, :string
    field :country, :string, default: "Brasil"
    field :postal_code, :string

    field :is_active, :boolean, default: true

    has_many :users, ExDesk.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @required_fields [:name]
  @optional_fields [
    :domain,
    :notes,
    :phone,
    :website,
    :address,
    :city,
    :state,
    :country,
    :postal_code,
    :is_active
  ]

  @doc """
  Changeset for creating or updating an organization.
  """
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:name, min: 2, max: 255)
    |> validate_format(:domain, ~r/^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,}$/i,
      message: "must be a valid domain (e.g. company.com)"
    )
    |> validate_format(:website, ~r/^https?:\/\/.+/,
      message: "must start with http:// or https://"
    )
    |> unique_constraint(:domain)
  end
end
