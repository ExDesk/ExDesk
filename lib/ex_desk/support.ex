defmodule ExDesk.Support do
  @moduledoc """
  The Support context.
  Handles all ticketing-related operations.
  """

  import Ecto.Query, warn: false
  alias ExDesk.Repo

  alias ExDesk.Support.{Group, Ticket, TicketActivity, TicketComment}

  # Bodyguard integration
  defdelegate authorize(action, user, params), to: ExDesk.Support.Policy

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

  @doc """
  Browses tickets with optional filters.

  ## Options
    * `:status` - Filter by status
    * `:priority` - Filter by priority
    * `:assignee_id` - Filter by assignee
    * `:requester_id` - Filter by requester
  """
  def browse_tickets(opts \\ []) do
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
  Fetches a ticket by ID with preloaded associations.
  Raises an exception if not found.
  """
  def fetch_ticket!(id) do
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
  Edits ticket details (subject, description, tags, etc).
  Should not be used for status transitions - use specific functions instead.
  """
  def edit_ticket_details(%Ticket{} = ticket, attrs, actor_id \\ nil) do
    attrs = Map.drop(attrs, [:status, "status"])
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
  Removes a ticket from the system.
  """
  def delete_ticket(%Ticket{} = ticket) do
    Repo.delete(ticket)
  end

  @doc """
  Awaits customer reply (open -> pending).
  Used when the agent needs more information.
  """
  def await_customer_reply(%Ticket{status: :open} = ticket, actor_id) do
    do_transition(ticket, :pending, actor_id, :awaiting_reply)
  end

  def await_customer_reply(%Ticket{}, _actor_id) do
    {:error, :invalid_status}
  end

  @doc """
  Pauses the ticket due to an external reason (any -> on_hold).
  Closed tickets cannot be put on hold.
  """
  def hold_ticket(ticket, actor_id, reason \\ nil)

  def hold_ticket(%Ticket{status: status} = ticket, actor_id, reason)
      when status not in [:closed] do
    do_transition(ticket, :on_hold, actor_id, :held, %{hold_reason: reason})
  end

  def hold_ticket(%Ticket{status: :closed}, _actor_id, _reason) do
    {:error, :ticket_closed}
  end

  @doc """
  Resumes a paused ticket (on_hold -> open).
  """
  def resume_ticket(%Ticket{status: :on_hold} = ticket, actor_id) do
    do_transition(ticket, :open, actor_id, :resumed)
  end

  def resume_ticket(%Ticket{}, _actor_id) do
    {:error, :invalid_status}
  end

  @doc """
  Resolves the ticket issue (any -> solved).
  Records the resolution timestamp.
  """
  def resolve_issue(%Ticket{status: status} = ticket, actor_id)
      when status not in [:closed, :solved] do
    extra = %{solved_at: DateTime.utc_now()}
    do_transition(ticket, :solved, actor_id, :resolved, extra)
  end

  def resolve_issue(%Ticket{status: :closed}, _actor_id) do
    {:error, :ticket_closed}
  end

  def resolve_issue(%Ticket{status: :solved}, _actor_id) do
    {:error, :already_solved}
  end

  @doc """
  Permanently closes the ticket (solved -> closed).
  Only administrators should call this function (check via Policy).
  """
  def close_ticket(%Ticket{status: :solved} = ticket, actor_id) do
    extra = %{closed_at: DateTime.utc_now()}
    do_transition(ticket, :closed, actor_id, :closed, extra)
  end

  def close_ticket(%Ticket{}, _actor_id) do
    {:error, :must_be_solved_first}
  end

  @doc """
  Reopens a ticket due to customer dissatisfaction (solved -> open).
  """
  def reopen_ticket(%Ticket{status: :solved} = ticket, actor_id) do
    do_transition(ticket, :open, actor_id, :reopened)
  end

  def reopen_ticket(%Ticket{}, _actor_id) do
    {:error, :invalid_status}
  end

  @dialyzer {:nowarn_function, do_transition: 4}
  @dialyzer {:nowarn_function, do_transition: 5}
  defp do_transition(ticket, new_status, actor_id, activity_action, extra_attrs \\ %{}) do
    alias ExDesk.Support.TicketStateMachine

    result =
      with {:ok, updated_ticket} <- TicketStateMachine.transition(ticket, new_status),
           {:ok, final_ticket} <- maybe_apply_extra_attrs(updated_ticket, extra_attrs) do
        log_activity(ticket.id, actor_id, activity_action)

        {:ok, final_ticket}
      end

    case result do
      {:ok, val} -> {:ok, val}
      {:error, reason} -> {:error, reason}
    end
  end

  @dialyzer {:nowarn_function, maybe_apply_extra_attrs: 2}
  defp maybe_apply_extra_attrs(ticket, extra_attrs) when extra_attrs == %{} do
    {:ok, ticket}
  end

  defp maybe_apply_extra_attrs(ticket, extra_attrs) do
    ticket
    |> Ecto.Changeset.change(extra_attrs)
    |> Repo.update()
  end

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

  @doc """
  Returns the total count of tickets in the system.
  """
  def count_total_tickets do
    Repo.aggregate(Ticket, :count, :id)
  end

  @doc """
  Returns the count of tickets with a specific status.
  """
  def count_tickets_by_status(status) do
    Ticket
    |> where([t], t.status == ^status)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Returns the count of open tickets.
  """
  def count_open_tickets do
    count_tickets_by_status(:open)
  end

  @doc """
  Returns the count of tickets assigned to a specific user.
  """
  def count_assigned_tickets(user_id) do
    Ticket
    |> where([t], t.assignee_id == ^user_id)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Calculates the average response time for solved tickets in hours.
  Currently returns 0.0 (placeholder).
  """
  def calculate_avg_response_time do
    0.0
  end
end
