defmodule ExDesk.Support.Policy do
  @moduledoc """
  Authorization policy for the Support context.

  Defines what actions each role can perform on tickets and groups.
  """
  @behaviour Bodyguard.Policy

  alias ExDesk.Accounts.User
  alias ExDesk.Support.Ticket

  # ============================================================================
  # Admin: Full access to everything
  # ============================================================================
  def authorize(_action, %User{role: :admin}, _resource), do: true

  # ============================================================================
  # Groups: Only Admin can manage
  # ============================================================================
  def authorize(:list_groups, %User{role: role}, _) when role in [:admin, :agent], do: true
  def authorize(:create_group, _, _), do: false
  def authorize(:update_group, _, _), do: false
  def authorize(:delete_group, _, _), do: false

  # ============================================================================
  # Tickets: Agents have broad access, Users limited to their own
  # ============================================================================

  # Agents can do everything with tickets
  def authorize(:list_all_tickets, %User{role: :agent}, _), do: true
  def authorize(:view_ticket, %User{role: :agent}, _), do: true
  def authorize(:assign_ticket, %User{role: :agent}, _), do: true
  def authorize(:update_ticket, %User{role: :agent}, _), do: true
  def authorize(:change_status, %User{role: :agent}, _), do: true
  def authorize(:change_priority, %User{role: :agent}, _), do: true
  def authorize(:add_internal_note, %User{role: :agent}, _), do: true

  # Users can create tickets
  def authorize(:create_ticket, %User{role: :user}, _), do: true

  # Users can only view/comment on their own tickets
  def authorize(:view_ticket, %User{role: :user, id: user_id}, %Ticket{requester_id: requester_id})
      when user_id == requester_id,
      do: true

  def authorize(:add_comment, %User{role: :user, id: user_id}, %Ticket{requester_id: requester_id})
      when user_id == requester_id,
      do: true

  def authorize(:list_my_tickets, %User{role: :user}, _), do: true

  # ============================================================================
  # Default: Deny
  # ============================================================================
  def authorize(_action, _user, _resource), do: false
end
