defmodule ExDeskWeb.TicketLive.FormComponent do
  use ExDeskWeb, :live_component

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
        <.input field={@form[:subject]} type="text" label="Subject" />
        <.input field={@form[:description]} type="textarea" label="Description" />
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
    changeset = Support.Ticket.create_changeset(ticket, %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"ticket" => ticket_params}, socket) do
    changeset =
      socket.assigns.ticket
      |> Support.Ticket.create_changeset(ticket_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"ticket" => ticket_params}, socket) do
    save_ticket(socket, socket.assigns.action, ticket_params)
  end

  defp save_ticket(socket, :new, ticket_params) do
    # Ensure current user is requester
    params = Map.put(ticket_params, "requester_id", socket.assigns.current_scope.user.id)

    case Support.create_ticket(params) do
      {:ok, _ticket} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ticket created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_ticket(socket, :edit, ticket_params) do
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
end
