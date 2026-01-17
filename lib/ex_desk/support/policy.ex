defmodule ExDesk.Support.Policy do
  @moduledoc """
  Authorization policy for the Support context.

  Defines what actions each role can perform on tickets and groups.

  ## Roles

  - `:admin` - Full access to all resources and actions
  - `:agent` - Can manage tickets, view groups, but cannot manage groups
  - `:user` - Can only create tickets and interact with their own tickets

  ## Usage

      iex> Policy.authorize(:delegate_ticket, admin_user, ticket)
      true

      iex> Policy.authorize(:delegate_ticket, regular_user, ticket)
      false

  ## Integration with Bodyguard

  This module implements `Bodyguard.Policy` and is used via:

      Bodyguard.permit(ExDesk.Support, :action, user, resource)
  """
  @behaviour Bodyguard.Policy

  alias ExDesk.Accounts.User
  alias ExDesk.Support.Ticket

  @doc """
  Authorizes an action for a user on a given resource.

  Returns `true` if the action is permitted, `false` otherwise.

  ## Parameters

  - `action` - The action atom (e.g., `:create_ticket`, `:delegate_ticket`)
  - `user` - The `%User{}` struct with a `:role` field
  - `resource` - The resource being accessed (can be `nil`, a `%Ticket{}`, etc.)

  ## Actions

  ### Group Actions
  - `:list_groups` - View available groups (Admin, Agent)
  - `:create_group` - Create a new group (Admin only)
  - `:update_group` - Update an existing group (Admin only)
  - `:delete_group` - Delete a group (Admin only)

  ### Ticket Actions
  - `:view_queue` - View all tickets in the queue (Admin, Agent)
  - `:list_my_tickets` - View own tickets (All roles)
  - `:view_ticket` - View a single ticket (Admin, Agent, or ticket owner)
  - `:create_ticket` - Create a new ticket (All roles)
  - `:edit_ticket_details` - Edit ticket fields (Admin, Agent)
  - `:assign_ticket` - Assign ticket to an agent (Admin, Agent)
  - `:transition_ticket` - Change ticket status (Admin, Agent)
  - `:escalate_ticket` - Change ticket priority (Admin, Agent)
  - `:add_comment` - Add a public comment (Admin, Agent, or ticket owner)
  - `:annotate_internally` - Add an internal note (Admin, Agent)
  - `:close_ticket` - Close a solved ticket (Admin only)
  """

  # Admin: Full access to everything
  def authorize(_action, %User{role: :admin}, _resource), do: true

  # Groups: Only Admin can manage
  def authorize(:list_groups, %User{role: role}, _) when role in [:admin, :agent], do: true
  def authorize(:create_group, _, _), do: false
  def authorize(:update_group, _, _), do: false
  def authorize(:delete_group, _, _), do: false

  def authorize(:view_queue, %User{role: :agent}, _), do: true
  def authorize(:view_ticket, %User{role: :agent}, _), do: true
  def authorize(:assign_ticket, %User{role: :agent}, _), do: true
  def authorize(:edit_ticket_details, %User{role: :agent}, _), do: true
  def authorize(:transition_ticket, %User{role: :agent}, _), do: true
  def authorize(:escalate_ticket, %User{role: :agent}, _), do: true
  def authorize(:annotate_internally, %User{role: :agent}, _), do: true
  def authorize(:close_ticket, %User{role: :agent}, _), do: false
  def authorize(:create_ticket, %User{role: :user}, _), do: true

  def authorize(:view_ticket, %User{role: :user, id: user_id}, %Ticket{requester_id: requester_id})
      when user_id == requester_id,
      do: true

  def authorize(:add_comment, %User{role: :user, id: user_id}, %Ticket{requester_id: requester_id})
      when user_id == requester_id,
      do: true

  def authorize(:list_my_tickets, %User{role: :user}, _), do: true

  def authorize(_action, _user, _resource), do: false
end
