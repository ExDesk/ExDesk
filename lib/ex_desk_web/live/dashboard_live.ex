defmodule ExDeskWeb.DashboardLive do
  use ExDeskWeb, :live_view

  alias ExDesk.Support

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} spaces={@spaces}>
      <div class="p-8">
        <div class="mx-auto max-w-7xl">
          <div class="mb-8">
            <h1 class="text-3xl font-mono font-bold tracking-tight text-base-content">Dashboard</h1>

            <p class="mt-2 text-lg text-base-content/70">Overview of your service desk status.</p>
          </div>

          <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
            <!-- Stat Card 1 -->
            <div class="card bg-base-200/50 border border-base-300 shadow-sm">
              <div class="card-body">
                <div class="flex items-center justify-between">
                  <div>
                    <p class="text-sm font-medium text-base-content/60">Total Tickets</p>

                    <p
                      id="stat-total-tickets"
                      class="text-3xl font-mono font-bold tracking-tight mt-1 text-primary"
                    >
                      {@total_tickets}
                    </p>
                  </div>

                  <div class="p-3 bg-primary/10 rounded-full">
                    <.icon name="hero-ticket" class="size-6 text-primary" />
                  </div>
                </div>

                <div class="mt-4 flex items-center text-sm text-base-content/60">
                  <span>
                    Last 7d: {@tickets_created_last_7} (prev: {@tickets_created_prev_7})
                  </span>
                </div>
              </div>
            </div>
            <!-- Stat Card 2 -->
            <div class="card bg-base-200/50 border border-base-300 shadow-sm">
              <div class="card-body">
                <div class="flex items-center justify-between">
                  <div>
                    <p class="text-sm font-medium text-base-content/60">Active Tickets</p>

                    <p
                      id="stat-active-tickets"
                      class="text-3xl font-mono font-bold tracking-tight mt-1 text-warning"
                    >
                      {@active_tickets}
                    </p>
                  </div>

                  <div class="p-3 bg-warning/10 rounded-full">
                    <.icon name="hero-exclamation-circle" class="size-6 text-warning" />
                  </div>
                </div>

                <div class="mt-4 flex items-center text-sm text-base-content/60">
                  <span>Open + pending + on hold</span>
                </div>
              </div>
            </div>
            <!-- Stat Card 3 -->
            <div class="card bg-base-200/50 border border-base-300 shadow-sm">
              <div class="card-body">
                <div class="flex items-center justify-between">
                  <div>
                    <p class="text-sm font-medium text-base-content/60">Assigned to Me</p>

                    <p
                      id="stat-assigned-to-me"
                      class="text-3xl font-mono font-bold tracking-tight mt-1 text-secondary"
                    >
                      {@assigned_tickets}
                    </p>
                  </div>

                  <div class="p-3 bg-secondary/10 rounded-full">
                    <.icon name="hero-user" class="size-6 text-secondary" />
                  </div>
                </div>

                <div class="mt-4 flex items-center text-sm text-base-content/60">
                  <span>{@assigned_high_priority} high priority</span>
                </div>
              </div>
            </div>
            <!-- Stat Card 4 -->
            <div class="card bg-base-200/50 border border-base-300 shadow-sm">
              <div class="card-body">
                <div class="flex items-center justify-between">
                  <div>
                    <p class="text-sm font-medium text-base-content/60">Avg First Response</p>

                    <p
                      id="stat-avg-response"
                      class="text-3xl font-mono font-bold tracking-tight mt-1 text-accent"
                    >
                      <%= if @avg_response_time do %>
                        {Float.round(@avg_response_time, 1)}h
                      <% else %>
                        N/A
                      <% end %>
                    </p>
                  </div>

                  <div class="p-3 bg-accent/10 rounded-full">
                    <.icon name="hero-clock" class="size-6 text-accent" />
                  </div>
                </div>

                <div class="mt-4 flex items-center text-sm text-base-content/60">
                  <span>Based on first public agent reply</span>
                </div>
              </div>
            </div>
          </div>
          <!-- Recent Activity Section placeholder -->
          <div class="mt-8 grid grid-cols-1 lg:grid-cols-2 gap-8">
            <div class="card bg-base-200/50 border border-base-300 shadow-sm">
              <div class="card-body">
                <h2 class="card-title text-base-content">Recent Activity</h2>

                <ul class="steps steps-vertical mt-4">
                  <li :for={activity <- @recent_activities} class="step step-primary">
                    <div class="text-left">
                      <span class="font-medium text-base-content">
                        <%= case activity.action do %>
                          <% :created -> %>
                            Ticket created
                          <% :assigned -> %>
                            Assigned to {if activity.actor, do: activity.actor.email, else: "System"}
                          <% :status_changed -> %>
                            Status changed for ticket
                          <% :commented -> %>
                            Comment added
                          <% other -> %>
                            {Phoenix.Naming.humanize(other)}
                        <% end %>
                      </span>
                      <span class="text-xs text-base-content/60 block">
                        {Calendar.strftime(activity.inserted_at, "%H:%M")} - Ticket #{activity.ticket_id}
                      </span>
                    </div>
                  </li>

                  <li
                    :if={length(@recent_activities) == 0}
                    class="text-base-content/50 italic text-sm py-4"
                  >
                    No recent activity found.
                  </li>
                </ul>
              </div>
            </div>

            <.pro_tip>
              You can use keyboard shortcuts to navigate quickly between tickets. Press '?' to see the full list.
            </.pro_tip>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    socket =
      socket
      |> assign(:total_tickets, Support.count_total_tickets())
      |> assign(:active_tickets, Support.count_active_tickets())
      |> assign(:assigned_tickets, Support.count_assigned_active_tickets(user.id))
      |> assign(
        :assigned_high_priority,
        Support.count_assigned_active_high_priority_tickets(user.id)
      )
      |> assign(:avg_response_time, Support.calculate_avg_response_time())
      |> assign(:tickets_created_last_7, Support.count_tickets_created_in_last_days(7))
      |> assign(:tickets_created_prev_7, Support.count_tickets_created_between_days(14, 7))
      |> assign(:recent_activities, Support.list_recent_activities(limit: 5))

    {:ok, socket}
  end
end
