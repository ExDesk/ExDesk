defmodule ExDesk.Support do
  @moduledoc """
  The Support context.
  Handles all ticketing-related operations.
  """

  import Ecto.Query, warn: false
  alias ExDesk.Repo

  alias ExDesk.Support.{Group, Space, Ticket, TicketActivity, TicketComment}

  @subtask_depth_limit 3

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

  @doc """
  Lists tickets for a given space.

  Returns tickets ordered by most recently created first.
  """
  def list_tickets_by_space(space_id) do
    Ticket
    |> where([t], t.space_id == ^space_id)
    |> order_by([t], asc_nulls_last: t.rank, desc: t.inserted_at, desc: t.id)
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
    |> Repo.preload([
      :parent,
      :space,
      :requester,
      :assignee,
      :group,
      comments: [:author],
      activities: [:actor]
    ])
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

  @doc """
  Creates a ticket inside a specific space.

  The `space_id` is set programmatically (not cast from user input).
  """
  def create_ticket_in_space(space_id, attrs \\ %{}, actor_id \\ nil) do
    Repo.transaction(fn ->
      with {:ok, ticket} <- do_create_ticket_in_space(space_id, attrs),
           {:ok, _activity} <- log_activity(ticket.id, actor_id, :created) do
        ticket
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Creates a sub-task (child ticket) for a parent ticket.

  The sub-task inherits `space_id` and `requester_id` from the parent.
  """
  def create_subtask(%Ticket{} = parent_ticket, attrs \\ %{}, actor_id \\ nil) when is_map(attrs) do
    Repo.transaction(fn ->
      changeset = build_subtask_changeset(parent_ticket, attrs)

      case ticket_depth(parent_ticket) do
        {:error, :circular_reference} ->
          Repo.rollback(
            Ecto.Changeset.add_error(changeset, :parent_id, "circular parent reference detected")
          )

        {:ok, depth} when depth + 1 > @subtask_depth_limit ->
          Repo.rollback(
            Ecto.Changeset.add_error(
              changeset,
              :parent_id,
              "exceeds maximum depth of #{@subtask_depth_limit}"
            )
          )

        {:ok, _depth} ->
          with {:ok, ticket} <- Repo.insert(changeset),
               {:ok, _activity} <- log_activity(ticket.id, actor_id, :created) do
            ticket
          else
            {:error, %Ecto.Changeset{} = cs} -> Repo.rollback(cs)
          end
      end
    end)
  end

  @doc """
  Lists all direct sub-tasks (children) for a ticket.
  """
  def list_subtasks(ticket_id) when is_integer(ticket_id) do
    Ticket
    |> where([t], t.parent_id == ^ticket_id)
    |> order_by([t], asc: t.inserted_at, asc: t.id)
    |> Repo.all()
  end

  @doc """
  Transitions a ticket to a new status using the state machine.

  This is the generic building block used by the Kanban board.
  """
  def transition_ticket(%Ticket{} = ticket, new_status, actor_id) when is_atom(new_status) do
    alias ExDesk.Support.TicketStateMachine

    with {:ok, updated_ticket} <- TicketStateMachine.transition(ticket, new_status),
         {:ok, _activity} <-
           log_activity(
             updated_ticket.id,
             actor_id,
             :status_changed,
             "status",
             %{value: ticket.status},
             %{value: updated_ticket.status}
           ) do
      {:ok, updated_ticket}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Moves a ticket on a Kanban board.

  - Performs a status transition (when changing columns)
  - Persists rank ordering for both source and destination columns
  """
  def move_ticket_on_kanban_board(
        space_id,
        ticket_id,
        from_column,
        to_column,
        from_ordered_ids,
        to_ordered_ids,
        actor_id
      ) do
    ticket = Repo.get!(Ticket, ticket_id)

    if ticket.space_id != space_id do
      {:error, :ticket_not_in_space}
    else
      new_status = status_for_column(ticket.status, from_column, to_column)

      with {:ok, ticket} <- maybe_transition(ticket, new_status, actor_id),
           {:ok, _} <-
             Repo.transaction(fn ->
               :ok = set_ranks_for_space(space_id, from_ordered_ids)
               :ok = set_ranks_for_space(space_id, to_ordered_ids)
               :ok
             end) do
        {:ok, ticket}
      else
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp maybe_transition(%Ticket{} = ticket, new_status, _actor_id)
       when new_status == ticket.status do
    {:ok, ticket}
  end

  defp maybe_transition(%Ticket{} = ticket, new_status, actor_id) do
    transition_ticket(ticket, new_status, actor_id)
  end

  defp do_create_ticket(attrs) do
    %Ticket{}
    |> Ticket.create_changeset(attrs)
    |> Repo.insert()
  end

  defp do_create_ticket_in_space(space_id, attrs) do
    status = normalize_status(Map.get(attrs, :status) || Map.get(attrs, "status") || :open)
    column = column_for_status(status)
    rank = next_rank_for_column(space_id, column)

    %Ticket{space_id: space_id, rank: rank}
    |> Ticket.create_changeset(attrs)
    |> Repo.insert()
  end

  defp build_subtask_changeset(%Ticket{} = parent_ticket, attrs) do
    status = normalize_status(Map.get(attrs, :status) || Map.get(attrs, "status") || :open)

    ticket =
      case parent_ticket.space_id do
        nil ->
          %Ticket{requester_id: parent_ticket.requester_id}

        space_id ->
          column = column_for_status(status)
          rank = next_rank_for_column(space_id, column)
          %Ticket{requester_id: parent_ticket.requester_id, space_id: space_id, rank: rank}
      end

    ticket
    |> Ticket.create_changeset(attrs)
    |> Ticket.set_parent(parent_ticket)
  end

  defp ticket_depth(%Ticket{id: id} = ticket) when is_integer(id) do
    do_ticket_depth(ticket.parent_id, MapSet.new([id]), 0)
  end

  defp do_ticket_depth(nil, _seen, depth), do: {:ok, depth}

  defp do_ticket_depth(parent_id, seen, depth) when is_integer(parent_id) do
    if MapSet.member?(seen, parent_id) do
      {:error, :circular_reference}
    else
      case Repo.get(Ticket, parent_id) do
        nil ->
          {:ok, depth + 1}

        parent_ticket ->
          do_ticket_depth(parent_ticket.parent_id, MapSet.put(seen, parent_id), depth + 1)
      end
    end
  end

  defp set_ranks_for_space(_space_id, nil), do: :ok

  defp set_ranks_for_space(space_id, ordered_ids) when is_list(ordered_ids) do
    ids = Enum.map(ordered_ids, &normalize_int_id/1)

    tickets_by_id =
      Ticket
      |> where([t], t.space_id == ^space_id and t.id in ^ids)
      |> Repo.all()
      |> Map.new(fn t -> {t.id, t} end)

    Enum.with_index(ids, 1)
    |> Enum.each(fn {id, idx} ->
      case Map.get(tickets_by_id, id) do
        nil ->
          :ok

        ticket ->
          ticket
          |> Ecto.Changeset.change(rank: idx)
          |> Repo.update!()
      end
    end)

    :ok
  end

  defp next_rank_for_column(space_id, column) do
    statuses = statuses_for_column(column)

    Ticket
    |> where([t], t.space_id == ^space_id and t.status in ^statuses)
    |> select([t], max(t.rank))
    |> Repo.one()
    |> case do
      nil -> 1
      max_rank -> max_rank + 1
    end
  end

  defp normalize_status(status) when is_atom(status), do: status

  defp normalize_status(status) when is_binary(status) do
    String.to_existing_atom(status)
  end

  defp normalize_status(_), do: :open

  defp column_for_status(status) when status in [:open], do: :todo
  defp column_for_status(status) when status in [:pending, :on_hold], do: :doing
  defp column_for_status(status) when status in [:solved, :closed], do: :done
  defp column_for_status(_), do: :todo

  defp statuses_for_column(:todo), do: [:open]
  defp statuses_for_column(:doing), do: [:pending, :on_hold]
  defp statuses_for_column(:done), do: [:solved, :closed]
  defp statuses_for_column(_), do: [:open]

  defp status_for_column(current_status, from_column, to_column) do
    from_column = normalize_column(from_column)
    to_column = normalize_column(to_column)

    if from_column == to_column do
      current_status
    else
      case to_column do
        :todo -> :open
        :doing -> :pending
        :done -> :solved
      end
    end
  end

  defp normalize_column(col) when col in [:todo, :doing, :done], do: col
  defp normalize_column("todo"), do: :todo
  defp normalize_column("doing"), do: :doing
  defp normalize_column("done"), do: :done
  defp normalize_column(_), do: :todo

  defp normalize_int_id(id) when is_integer(id), do: id
  defp normalize_int_id(id) when is_binary(id), do: String.to_integer(id)

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
    extra = %{custom_fields: Map.put(ticket.custom_fields || %{}, "hold_reason", reason)}
    do_transition(ticket, :on_hold, actor_id, :held, extra)
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
    extra = %{solved_at: DateTime.utc_now() |> DateTime.truncate(:second)}
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
    extra = %{closed_at: DateTime.utc_now() |> DateTime.truncate(:second)}
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

  @doc """
  Returns the most recent activities across all tickets.

  ## Options
    * `:limit` - Maximum number of activities to return (default: 10)
  """
  def list_recent_activities(opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)

    TicketActivity
    |> order_by([a], desc: a.inserted_at, desc: a.id)
    |> limit(^limit)
    |> Repo.all()
    |> Repo.preload([:actor, :ticket])
  end

  @doc """
  Returns the list of all spaces.
  """
  def list_spaces do
    Space
    |> order_by([s], asc: s.name)
    |> Repo.all()
  end

  @doc """
  Gets a single space by ID.
  Raises `Ecto.NoResultsError` if not found.
  """
  def get_space!(id), do: Repo.get!(Space, id)

  @doc """
  Gets a space by its key.
  Returns nil if not found.
  """
  def get_space_by_key(key) do
    Repo.get_by(Space, key: key)
  end

  @doc """
  Gets a space by its key.
  Raises `Ecto.NoResultsError` if not found.
  """
  def get_space_by_key!(key) do
    Space
    |> Repo.get_by!(key: key)
  end

  @doc """
  Creates a space.

  The `created_by_id` is set programmatically (not cast from user input).
  """
  def create_space(attrs, created_by_id) when is_map(attrs) and is_integer(created_by_id) do
    %Space{created_by_id: created_by_id}
    |> Space.changeset(attrs)
    |> Ecto.Changeset.validate_required([:created_by_id])
    |> Repo.insert()
  end

  @doc """
  Updates a space.
  """
  def update_space(%Space{} = space, attrs) do
    space
    |> Space.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a space.
  """
  def delete_space(%Space{} = space) do
    Repo.delete(space)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking space changes.
  """
  def change_space(%Space{} = space, attrs \\ %{}) do
    Space.changeset(space, attrs)
  end

  @doc """
  Returns the count of tickets in a space.
  """
  def count_tickets_by_space(%Space{id: space_id}) do
    Ticket
    |> where([t], t.space_id == ^space_id)
    |> Repo.aggregate(:count, :id)
  end
end
