defmodule ExDesk.Support.TicketStateMachine do
  @moduledoc """
  State machine for Ticket status transitions.

  Defines states and allowed transitions using Machinery.

  ## States
  - `open` - Ticket open, awaiting action
  - `pending` - Awaiting customer reply
  - `on_hold` - Paused due to external reason
  - `solved` - Issue resolved
  - `closed` - Ticket permanently closed

  ## Allowed Transitions
  - open → pending, on_hold, solved
  - pending → open, on_hold, solved
  - on_hold → open, pending, solved
  - solved → open, closed
  - closed → (no allowed transitions)

  ## Usage

      iex> ticket = %Ticket{status: :open}
      iex> TicketStateMachine.transition(ticket, :pending)
      {:ok, %Ticket{status: :pending}}
  """

  use Machinery,
    field: :status,
    states: ["open", "pending", "on_hold", "solved", "closed"],
    transitions: %{
      "open" => ["pending", "on_hold", "solved"],
      "pending" => ["open", "on_hold", "solved"],
      "on_hold" => ["open", "pending", "solved"],
      "solved" => ["open", "closed"]
    }

  alias ExDesk.Repo
  alias ExDesk.Support.Ticket

  @doc """
  Executes a status transition, converting atoms to strings.

  ## Parameters
  - `ticket` - The ticket to transition (with status as atom)
  - `new_status` - The new status as atom

  ## Returns
  - `{:ok, ticket}` - Successful transition
  - `{:error, reason}` - Invalid transition or persistence error
  """
  def transition(%Ticket{} = ticket, new_status) when is_atom(new_status) do
    ticket_with_string_status = %Ticket{ticket | status: to_string(ticket.status)}
    new_status_string = to_string(new_status)

    case Machinery.transition_to(ticket_with_string_status, __MODULE__, new_status_string) do
      {:ok, updated_ticket} ->
        final_status = String.to_existing_atom(updated_ticket.status)
        {:ok, %{updated_ticket | status: final_status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Persists the status transition to the database.
  Called automatically by Machinery after a valid transition.
  """
  def persist(%{id: nil} = ticket, new_status) do
    %{ticket | status: new_status}
  end

  def persist(ticket, new_status) do
    changeset =
      ticket
      |> Ecto.Changeset.change(status: String.to_existing_atom(new_status))
      |> add_timestamp_fields(new_status)

    case Repo.update(changeset) do
      {:ok, updated_ticket} ->
        %{updated_ticket | status: new_status}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp add_timestamp_fields(changeset, "solved") do
    Ecto.Changeset.put_change(changeset, :solved_at, DateTime.utc_now())
  end

  defp add_timestamp_fields(changeset, "closed") do
    Ecto.Changeset.put_change(changeset, :closed_at, DateTime.utc_now())
  end

  defp add_timestamp_fields(changeset, _status), do: changeset

  @doc """
  Checks if a transition is valid without executing it.
  """
  def valid_transition?(from_status, to_status)
      when is_atom(from_status) and is_atom(to_status) do
    transitions = %{
      open: [:pending, :on_hold, :solved],
      pending: [:open, :on_hold, :solved],
      on_hold: [:open, :pending, :solved],
      solved: [:open, :closed],
      closed: []
    }

    to_status in Map.get(transitions, from_status, [])
  end

  @doc """
  Returns the allowed transitions from a status.
  """
  def allowed_transitions(status) when is_atom(status) do
    transitions = %{
      open: [:pending, :on_hold, :solved],
      pending: [:open, :on_hold, :solved],
      on_hold: [:open, :pending, :solved],
      solved: [:open, :closed],
      closed: []
    }

    Map.get(transitions, status, [])
  end
end
