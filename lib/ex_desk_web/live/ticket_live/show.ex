defmodule ExDeskWeb.TicketLive.Show do
  use ExDeskWeb, :live_view

  alias ExDesk.Support

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} spaces={@spaces}>
      <div class="header">
        <h1>{@ticket.subject}</h1>
      </div>

      <div class="ticket-details">
        <p>{@ticket.description}</p>

        <p>Status: {@ticket.status}</p>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    ticket = Support.fetch_ticket!(id)
    {:ok, assign(socket, :ticket, ticket)}
  end
end
