defmodule ExDesk.Support do
  @moduledoc """
  The Support context.
  Handles all ticketing-related operations.
  """

  import Ecto.Query, warn: false
  alias ExDesk.Repo

  alias ExDesk.Support.{Group, Ticket, TicketComment, TicketActivity}

  # Bodyguard integration
  defdelegate authorize(action, user, params), to: ExDesk.Support.Policy

  # ============================================================================
  # Groups
  # ============================================================================

  @doc """
  Returns the list of groups.
  """
  def list_groups do
    Repo.all(Group)
  end

  @doc """
  Gets a single group.
  """
  def get_group!(id), do: Repo.get!(Group, id)

  @doc """
  Creates a group.
  """
  def create_group(attrs \\ %{}) do
    %Group{}
    |> Group.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a group.
  """
  def update_group(%Group{} = group, attrs) do
    group
    |> Group.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a group.
  """
  def delete_group(%Group{} = group) do
    Repo.delete(group)
  end

  # ============================================================================
  # Tickets
  # ============================================================================

  @doc """
  Returns the list of tickets.

  ## Options
    * `:status` - Filter by status
    * `:priority` - Filter by priority
    * `:assignee_id` - Filter by assignee
    * `:requester_id` - Filter by requester
  """
  def list_tickets(opts \\ []) do
    Ticket
    |> filter_by_status(opts[:status])
    |> filter_by_priority(opts[:priority])
    |> filter_by_assignee(opts[:assignee_id])
    |> filter_by_requester(opts[:requester_id])
    |> order_by([t], desc: t.inserted_at)
    |> Repo.all()
  end

  defp filter_by_status(query, nil), do: query
  defp filter_by_status(query, status), do: where(query, [t], t.status == ^status)

  defp filter_by_priority(query, nil), do: query
  defp filter_by_priority(query, priority), do: where(query, [t], t.priority == ^priority)

  defp filter_by_assignee(query, nil), do: query

  defp filter_by_assignee(query, assignee_id),
    do: where(query, [t], t.assignee_id == ^assignee_id)

  defp filter_by_requester(query, nil), do: query

  defp filter_by_requester(query, requester_id),
    do: where(query, [t], t.requester_id == ^requester_id)

  @doc """
  Gets a single ticket with preloaded associations.
  """
  def get_ticket!(id) do
    Ticket
    |> Repo.get!(id)
    |> Repo.preload([:requester, :assignee, :group, :comments, :activities])
  end

  @doc """
  Creates a ticket and logs the activity.
  """
  def create_ticket(attrs \\ %{}, actor_id \\ nil) do
    Repo.transaction(fn ->
      with {:ok, ticket} <- do_create_ticket(attrs),
           {:ok, _activity} <- log_activity(ticket.id, actor_id, :created) do
        ticket
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  defp do_create_ticket(attrs) do
    %Ticket{}
    |> Ticket.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a ticket and logs changes.
  """
  def update_ticket(%Ticket{} = ticket, attrs, actor_id \\ nil) do
    changeset = Ticket.update_changeset(ticket, attrs)

    Repo.transaction(fn ->
      with {:ok, updated_ticket} <- Repo.update(changeset),
           :ok <- log_changes(ticket, updated_ticket, actor_id) do
        updated_ticket
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  defp log_changes(old_ticket, new_ticket, actor_id) do
    changes = [
      {:status, :status_changed},
      {:priority, :priority_changed},
      {:assignee_id, :assigned},
      {:group_id, :group_changed}
    ]

    Enum.each(changes, fn {field, action} ->
      old_val = Map.get(old_ticket, field)
      new_val = Map.get(new_ticket, field)

      if old_val != new_val do
        log_activity(new_ticket.id, actor_id, action, Atom.to_string(field), %{value: old_val}, %{
          value: new_val
        })
      end
    end)

    :ok
  end

  @doc """
  Deletes a ticket.
  """
  def delete_ticket(%Ticket{} = ticket) do
    Repo.delete(ticket)
  end

  # ============================================================================
  # Comments
  # ============================================================================

  @doc """
  Adds a comment to a ticket.
  """
  def add_comment(ticket_id, author_id, attrs) do
    attrs = Map.merge(attrs, %{ticket_id: ticket_id, author_id: author_id})

    Repo.transaction(fn ->
      with {:ok, comment} <- do_add_comment(attrs),
           {:ok, _activity} <- log_activity(ticket_id, author_id, :commented) do
        comment
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  defp do_add_comment(attrs) do
    %TicketComment{}
    |> TicketComment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Lists comments for a ticket.
  """
  def list_comments(ticket_id, opts \\ []) do
    public_only = Keyword.get(opts, :public_only, false)

    TicketComment
    |> where([c], c.ticket_id == ^ticket_id)
    |> maybe_filter_public(public_only)
    |> order_by([c], asc: c.inserted_at)
    |> Repo.all()
    |> Repo.preload(:author)
  end

  defp maybe_filter_public(query, false), do: query
  defp maybe_filter_public(query, true), do: where(query, [c], c.is_public == true)

  @doc """
  Logs an activity for a ticket.
  """
  def log_activity(ticket_id, actor_id, action, field \\ nil, old_value \\ nil, new_value \\ nil) do
    %TicketActivity{}
    |> TicketActivity.changeset(%{
      ticket_id: ticket_id,
      actor_id: actor_id,
      action: action,
      field: field,
      old_value: old_value,
      new_value: new_value
    })
    |> Repo.insert()
  end

  @doc """
  Lists activities for a ticket.
  """
  def list_activities(ticket_id) do
    TicketActivity
    |> where([a], a.ticket_id == ^ticket_id)
    |> order_by([a], desc: a.inserted_at)
    |> Repo.all()
    |> Repo.preload(:actor)
  end
end
