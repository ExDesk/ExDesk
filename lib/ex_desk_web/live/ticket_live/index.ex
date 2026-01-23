defmodule ExDeskWeb.TicketLive.Index do
  use ExDeskWeb, :live_view

  alias ExDesk.Support

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} spaces={@spaces}>
      <div class="header">
        <h1>Tickets</h1>
        <.link navigate={~p"/tickets/new"}>New Ticket</.link>
      </div>

      <div class="tickets-list">
        <.table id="tickets" rows={@tickets}>
          <:col :let={ticket} label="Subject">
            <.link
              navigate={~p"/tickets/#{ticket}?return_to=/tickets"}
              class="font-medium hover:underline"
            >
              {ticket.subject}
            </.link>
          </:col>

          <:col :let={ticket} label="Status">
            <span class={["badge", status_badge_class(ticket.status)]}>{ticket.status}</span>
          </:col>

          <:col :let={ticket} label="Priority">
            <span class={["badge", priority_badge_class(ticket.priority)]}>{ticket.priority}</span>
          </:col>

          <:action :let={ticket}><.link navigate={~p"/tickets/#{ticket}/edit"}>Edit</.link></:action>
        </.table>
      </div>

      <.modal
        :if={@live_action in [:new, :edit]}
        id="ticket-modal"
        show
        on_cancel={JS.patch(~p"/tickets")}
      >
        <.live_component
          module={ExDeskWeb.TicketLive.FormComponent}
          id={@ticket.id || :new}
          title={@page_title}
          action={@live_action}
          ticket={@ticket}
          patch={@patch}
          current_scope={@current_scope}
          spaces={@spaces}
        />
      </.modal>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    tickets = Support.browse_tickets()
    {:ok, assign(socket, :tickets, tickets)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Ticket")
    |> assign(:patch, ~p"/tickets")
    |> assign(:ticket, %Support.Ticket{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Tickets")
    |> assign(:patch, ~p"/tickets")
    |> assign(:ticket, nil)
    |> assign(:tickets, Support.browse_tickets())
  end

  defp apply_action(socket, :edit, %{"id" => id} = params) do
    ticket = Support.fetch_ticket!(id)
    patch = safe_return_to(Map.get(params, "return_to"))

    socket
    |> assign(:page_title, "Edit Ticket")
    |> assign(:patch, patch)
    |> assign(:ticket, ticket)
  end

  defp safe_return_to(nil), do: ~p"/tickets"

  defp safe_return_to(val) when is_binary(val) do
    val = String.trim(val)

    cond do
      val == "" -> ~p"/tickets"
      String.starts_with?(val, "//") -> ~p"/tickets"
      String.starts_with?(val, "/") -> val
      true -> ~p"/tickets"
    end
  end

  defp status_badge_class(:open), do: "badge-warning"
  defp status_badge_class(:pending), do: "badge-info"
  defp status_badge_class(:on_hold), do: "badge-ghost"
  defp status_badge_class(:solved), do: "badge-success"
  defp status_badge_class(:closed), do: "badge-neutral"
  defp status_badge_class(_), do: ""

  defp priority_badge_class(:low), do: "badge-ghost"
  defp priority_badge_class(:normal), do: "badge-info"
  defp priority_badge_class(:high), do: "badge-warning"
  defp priority_badge_class(:urgent), do: "badge-error"
  defp priority_badge_class(_), do: ""
end
