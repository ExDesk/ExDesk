defmodule ExDeskWeb.TicketLive.FormComponent do
  use ExDeskWeb, :live_component

  import ExDeskWeb.Authorization, only: [can?: 3]

  alias ExDesk.Accounts
  alias ExDesk.Support

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>{@title}</.header>

      <.simple_form
        for={@form}
        id="ticket-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          :if={@action == :new}
          field={@form[:space_id]}
          type="select"
          label="Space"
          prompt="Select a space"
          options={@space_options}
        />
        <.input field={@form[:subject]} type="text" label="Subject" />
        <.input field={@form[:description]} type="textarea" label="Description" />

        <.input
          :if={@show_assignee?}
          field={@form[:assignee_id]}
          type="select"
          label="Assignee"
          prompt="Unassigned"
          options={@assignee_options}
        />

        <.input
          field={@form[:priority]}
          type="select"
          label="Priority"
          options={[Low: :low, Normal: :normal, High: :high, Urgent: :urgent]}
        />
        <:actions><.button phx-disable-with="Saving...">Save Ticket</.button></:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{ticket: ticket} = assigns, socket) do
    show_assignee? = can?(assigns.current_scope.user, :assign_ticket, ticket)

    spaces = Map.get(assigns, :spaces, [])

    assignee_options =
      if show_assignee? do
        Accounts.list_agents()
        |> Enum.map(fn u -> {u.email, u.id} end)
      else
        []
      end

    space_options = space_options(spaces)

    changeset = changeset_for_action(assigns.action, ticket, %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:show_assignee?, show_assignee?)
     |> assign(:assignee_options, assignee_options)
     |> assign(:space_options, space_options)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"ticket" => ticket_params}, socket) do
    ticket_params = sanitize_ticket_params(socket, ticket_params)

    changeset =
      socket.assigns.action
      |> changeset_for_action(socket.assigns.ticket, ticket_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"ticket" => ticket_params}, socket) do
    save_ticket(socket, socket.assigns.action, ticket_params)
  end

  defp save_ticket(socket, :new, ticket_params) do
    params = sanitize_ticket_params(socket, ticket_params)

    changeset = changeset_for_action(:new, socket.assigns.ticket, params)

    if changeset.valid? do
      space_id = Ecto.Changeset.get_field(changeset, :space_id)
      actor_id = socket.assigns.current_scope.user.id
      params = Map.drop(params, ["space_id"])

      case Support.create_ticket_in_space(space_id, params, actor_id) do
        {:ok, _ticket} ->
          {:noreply,
           socket
           |> put_flash(:info, "Ticket created successfully")
           |> push_patch(to: socket.assigns.patch)}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign_form(socket, validate_changeset(changeset))}
      end
    else
      {:noreply, assign_form(socket, validate_changeset(changeset))}
    end
  end

  defp save_ticket(socket, :edit, ticket_params) do
    ticket_params = sanitize_ticket_params(socket, ticket_params)

    case Support.edit_ticket_details(socket.assigns.ticket, ticket_params) do
      {:ok, _ticket} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ticket updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp changeset_for_action(:edit, ticket, attrs),
    do: Support.Ticket.update_changeset(ticket, attrs)

  defp changeset_for_action(:new, ticket, attrs) do
    new_ticket_changeset(ticket, attrs)
  end

  defp changeset_for_action(_action, ticket, attrs),
    do: Support.Ticket.create_changeset(ticket, attrs)

  defp sanitize_ticket_params(socket, ticket_params) when is_map(ticket_params) do
    ticket_params =
      case socket.assigns.action do
        :new -> Map.put(ticket_params, "requester_id", socket.assigns.current_scope.user.id)
        _ -> Map.drop(ticket_params, ["requester_id"])
      end

    if can?(socket.assigns.current_scope.user, :assign_ticket, socket.assigns.ticket) do
      ticket_params
    else
      Map.drop(ticket_params, ["assignee_id"])
    end
  end

  defp new_ticket_changeset(ticket, attrs) do
    ticket
    |> Support.Ticket.create_changeset(attrs)
    |> Ecto.Changeset.cast(attrs, [:space_id])
    |> Ecto.Changeset.validate_required([:space_id])
  end

  defp validate_changeset(%Ecto.Changeset{} = changeset),
    do: Map.put(changeset, :action, :validate)

  defp space_options(spaces) when is_list(spaces) do
    spaces
    |> Enum.map(fn s -> {"#{s.name} (#{s.key})", s.id} end)
    |> Enum.sort_by(fn {label, _id} -> label end)
  end
end
