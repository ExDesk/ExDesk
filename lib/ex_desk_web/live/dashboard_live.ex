defmodule ExDeskWeb.DashboardLive do
  use ExDeskWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-8">
      <div class="mx-auto max-w-7xl">
        <div class="mb-8">
          <h1 class="text-3xl font-bold tracking-tight text-base-content">Dashboard</h1>
          
          <p class="mt-2 text-lg text-base-content/70">Overview of your service desk status.</p>
        </div>
        
        <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
          <!-- Stat Card 1 -->
          <div class="card bg-base-100 shadow-xl border border-base-200">
            <div class="card-body">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm font-medium text-base-content/60">Total Tickets</p>
                  
                  <p class="text-3xl font-bold mt-1 text-primary">24</p>
                </div>
                
                <div class="p-3 bg-primary/10 rounded-full">
                  <.icon name="hero-ticket" class="size-6 text-primary" />
                </div>
              </div>
              
              <div class="mt-4 flex items-center text-sm text-success">
                <.icon name="hero-arrow-trending-up" class="size-4 mr-1" />
                <span>12% from last week</span>
              </div>
            </div>
          </div>
          <!-- Stat Card 2 -->
          <div class="card bg-base-100 shadow-xl border border-base-200">
            <div class="card-body">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm font-medium text-base-content/60">Open Tickets</p>
                  
                  <p class="text-3xl font-bold mt-1 text-warning">8</p>
                </div>
                
                <div class="p-3 bg-warning/10 rounded-full">
                  <.icon name="hero-exclamation-circle" class="size-6 text-warning" />
                </div>
              </div>
              
              <div class="mt-4 flex items-center text-sm text-base-content/60">
                <span>Requires attention</span>
              </div>
            </div>
          </div>
          <!-- Stat Card 3 -->
          <div class="card bg-base-100 shadow-xl border border-base-200">
            <div class="card-body">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm font-medium text-base-content/60">Assigned to Me</p>
                  
                  <p class="text-3xl font-bold mt-1 text-secondary">5</p>
                </div>
                
                <div class="p-3 bg-secondary/10 rounded-full">
                  <.icon name="hero-user" class="size-6 text-secondary" />
                </div>
              </div>
              
              <div class="mt-4 flex items-center text-sm text-base-content/60">
                <span>3 high priority</span>
              </div>
            </div>
          </div>
          <!-- Stat Card 4 -->
          <div class="card bg-base-100 shadow-xl border border-base-200">
            <div class="card-body">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm font-medium text-base-content/60">Avg Response Time</p>
                  
                  <p class="text-3xl font-bold mt-1 text-accent">2.4h</p>
                </div>
                
                <div class="p-3 bg-accent/10 rounded-full">
                  <.icon name="hero-clock" class="size-6 text-accent" />
                </div>
              </div>
              
              <div class="mt-4 flex items-center text-sm text-success">
                <.icon name="hero-arrow-trending-down" class="size-4 mr-1" />
                <span>15min faster</span>
              </div>
            </div>
          </div>
        </div>
        <!-- Recent Activity Section placeholder -->
        <div class="mt-8 grid grid-cols-1 lg:grid-cols-2 gap-8">
          <div class="card bg-base-100 shadow-xl border border-base-200">
            <div class="card-body">
              <h2 class="card-title text-base-content">Recent Activity</h2>
              
              <ul class="steps steps-vertical mt-4">
                <li class="step step-primary">Ticket #123 created</li>
                
                <li class="step step-primary">Asset assigned to John Doe</li>
                
                <li class="step">Server maintenance scheduled</li>
                
                <li class="step">New license purchased</li>
              </ul>
            </div>
          </div>
          
          <div class="card bg-gradient-to-br from-indigo-500 to-purple-600 text-white shadow-xl">
            <div class="card-body">
              <h2 class="card-title">Pro Tip</h2>
              
              <p>
                You can use keyboard shortcuts to navigate quickly between tickets. Press '?' to see the full list.
              </p>
              
              <div class="card-actions justify-end mt-4">
                <button class="btn btn-sm btn-ghost bg-white/20 text-white hover:bg-white/30 border-none">
                  Learn More
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
