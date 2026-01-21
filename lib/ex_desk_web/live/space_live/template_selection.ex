defmodule ExDeskWeb.SpaceLive.TemplateSelection do
  use ExDeskWeb, :live_view

  @templates [
    %{
      id: "kanban",
      name: "Kanban",
      description: "Work efficiently and visualize work on a board with to do, doing, and done.",
      icon: "hero-view-columns",
      color: "#22C55E"
    },
    %{
      id: "service_desk",
      name: "Service Desk",
      description: "Create one place to collect and manage any type of request.",
      icon: "hero-inbox",
      color: "#F97316"
    },
    %{
      id: "project",
      name: "Project",
      description:
        "Plan, track, and report on big chunks of work, such as a program or initiative.",
      icon: "hero-clipboard-document-list",
      color: "#3B82F6"
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Choose a template")
     |> assign(:templates, @templates)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-4xl mx-auto space-y-8">
        <div class="text-center">
          <h1 class="text-3xl font-bold mb-2">Choose a template</h1>
          
          <p class="text-base-content/60">
            Templates help you get started quickly with pre-configured settings
          </p>
        </div>
        
        <div class="grid gap-6 md:grid-cols-3">
          <.link
            :for={template <- @templates}
            id={"template-#{template.id}"}
            navigate={~p"/spaces/new/#{template.id}"}
            class="card bg-base-200 hover:bg-base-300 hover:shadow-lg transition-all cursor-pointer group"
          >
            <div class="card-body">
              <div
                class="size-12 rounded-xl flex items-center justify-center mb-4 group-hover:scale-110 transition-transform"
                style={"background-color: #{template.color}"}
              >
                <.icon name={template.icon} class="size-6 text-white" />
              </div>
              
              <h3 class="card-title text-lg">{template.name}</h3>
              
              <p class="text-sm text-base-content/60">{template.description}</p>
            </div>
          </.link>
        </div>
        
        <div class="text-center">
          <.link navigate={~p"/spaces"} class="btn btn-ghost">
            <.icon name="hero-arrow-left" class="size-4" /> Back to Spaces
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
