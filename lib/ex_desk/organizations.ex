defmodule ExDesk.Organizations do
  @moduledoc """
  Context for managing organizations.
  Organizations group users and can have tickets/assets associated.
  """

  import Ecto.Query, warn: false
  alias ExDesk.Repo
  alias ExDesk.Organizations.Organization

  @doc """
  Returns the list of all organizations.

  ## Examples

      iex> list_organizations()
      [%Organization{}, ...]

  """
  def list_organizations do
    Repo.all(Organization)
  end

  @doc """
  Returns only active organizations.
  """
  def list_active_organizations do
    Organization
    |> where([o], o.is_active == true)
    |> order_by([o], asc: o.name)
    |> Repo.all()
  end

  @doc """
  Gets a single organization by ID.

  Raises `Ecto.NoResultsError` if not found.

  ## Examples

      iex> get_organization!(123)
      %Organization{}

      iex> get_organization!(456)
      ** (Ecto.NoResultsError)

  """
  def get_organization!(id), do: Repo.get!(Organization, id)

  @doc """
  Gets a single organization by ID, returns nil if not found.
  """
  def get_organization(id), do: Repo.get(Organization, id)

  @doc """
  Gets an organization by domain.
  """
  def get_organization_by_domain(domain) when is_binary(domain) do
    Repo.get_by(Organization, domain: String.downcase(domain))
  end

  @doc """
  Creates a new organization.

  ## Examples

      iex> create_organization(%{name: "Company X"})
      {:ok, %Organization{}}

      iex> create_organization(%{name: nil})
      {:error, %Ecto.Changeset{}}

  """
  def create_organization(attrs \\ %{}) do
    %Organization{}
    |> Organization.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an existing organization.

  ## Examples

      iex> update_organization(organization, %{name: "New Name"})
      {:ok, %Organization{}}

      iex> update_organization(organization, %{name: nil})
      {:error, %Ecto.Changeset{}}

  """
  def update_organization(%Organization{} = organization, attrs) do
    organization
    |> Organization.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an organization.

  ## Examples

      iex> delete_organization(organization)
      {:ok, %Organization{}}

      iex> delete_organization(organization)
      {:error, %Ecto.Changeset{}}

  """
  def delete_organization(%Organization{} = organization) do
    Repo.delete(organization)
  end

  @doc """
  Returns a changeset for tracking changes.

  ## Examples

      iex> change_organization(organization)
      %Ecto.Changeset{data: %Organization{}}

  """
  def change_organization(%Organization{} = organization, attrs \\ %{}) do
    Organization.changeset(organization, attrs)
  end

  @doc """
  Searches organizations by term (name or domain).
  """
  def search_organizations(term) when is_binary(term) do
    search_term = "%#{term}%"

    Organization
    |> where([o], ilike(o.name, ^search_term) or ilike(o.domain, ^search_term))
    |> order_by([o], asc: o.name)
    |> Repo.all()
  end

  @doc """
  Counts the number of users in an organization.
  """
  def count_users(%Organization{id: id}) do
    ExDesk.Accounts.User
    |> where([u], u.organization_id == ^id)
    |> Repo.aggregate(:count)
  end
end
