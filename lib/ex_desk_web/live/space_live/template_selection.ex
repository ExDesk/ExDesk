defmodule ExDeskWeb.SpaceLive.TemplateSelection do
  use ExDeskWeb, :live_view

  @templates [
    %{
      id: "kanban",
      name: "Kanban",
      description: "Work efficiently and visualize work on a board with to do, doing, and done."
    },
    %{
      id: "service_desk",
      name: "Service Desk",
      description: "Create one place to collect and manage any type of request."
    },
    %{
      id: "project",
      name: "Project",
      description:
        "Plan, track, and report on big chunks of work, such as a program or initiative."
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    templates = @templates
    selected = List.first(templates)

    {:ok,
     socket
     |> assign(:page_title, "Choose a template")
     |> assign(:templates, templates)
     |> assign(:selected_template, selected)}
  end

  @impl true
  def handle_event("select_template", %{"id" => id}, socket) do
    selected = Enum.find(socket.assigns.templates, fn t -> t.id == id end)
    {:noreply, assign(socket, :selected_template, selected)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-6xl mx-auto space-y-8">
        <div class="text-center">
          <h1 class="text-3xl font-bold mb-2">Choose a template</h1>
          
          <p class="text-base-content/60">
            Templates help you get started quickly with pre-configured settings
          </p>
        </div>
        
        <div class="grid gap-6 lg:grid-cols-2">
          <%!-- Template Cards Column --%>
          <div class="space-y-4">
            <div
              :for={template <- @templates}
              id={"template-#{template.id}"}
              phx-click="select_template"
              phx-value-id={template.id}
              class={[
                "card cursor-pointer transition-all",
                template.id == @selected_template.id && "ring-2 ring-primary bg-base-200 selected",
                template.id != @selected_template.id && "bg-base-200/50 hover:bg-base-200"
              ]}
            >
              <div class="card-body p-4">
                <div class="flex items-center gap-4">
                  <div class="flex-1">
                    <h3 class="font-semibold">{template.name}</h3>
                    
                    <p class="text-sm text-base-content/60">{template.description}</p>
                  </div>
                  
                  <div :if={template.id == @selected_template.id} class="text-primary">
                    <.icon name="hero-check-circle-solid" class="size-6" />
                  </div>
                </div>
              </div>
            </div>
          </div>
           <%!-- Live Preview Column --%>
          <div class="card bg-base-200" id="live-preview">
            <div class="card-body">
              <h3 class="font-semibold mb-4">{@selected_template.name} Preview</h3>
              
              <div class="bg-base-300 rounded-xl p-4 min-h-[300px]">
                <.template_preview template={@selected_template.id} />
              </div>
            </div>
          </div>
        </div>
        
        <div class="flex justify-center gap-4">
          <.link navigate={~p"/spaces"} class="btn btn-ghost">
            <.icon name="hero-arrow-left" class="size-4" /> Back
          </.link>
          <.link navigate={~p"/spaces/new/#{@selected_template.id}"} class="btn btn-primary">
            Continue <.icon name="hero-arrow-right" class="size-4" />
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp template_preview(%{template: "kanban"} = assigns) do
    ~H"""
    <div class="grid grid-cols-3 gap-3 h-full">
      <div class="space-y-2">
        <div class="text-xs font-semibold text-base-content/60 uppercase">To Do</div>
        
        <div class="bg-base-100 rounded-lg p-2 h-16 shadow-sm"></div>
        
        <div class="bg-base-100 rounded-lg p-2 h-12 shadow-sm"></div>
      </div>
      
      <div class="space-y-2">
        <div class="text-xs font-semibold text-base-content/60 uppercase">Doing</div>
        
        <div class="bg-base-100 rounded-lg p-2 h-20 shadow-sm"></div>
      </div>
      
      <div class="space-y-2">
        <div class="text-xs font-semibold text-base-content/60 uppercase">Done</div>
        
        <div class="bg-base-100 rounded-lg p-2 h-10 shadow-sm"></div>
        
        <div class="bg-base-100 rounded-lg p-2 h-14 shadow-sm"></div>
      </div>
    </div>
    """
  end

  defp template_preview(%{template: "service_desk"} = assigns) do
    ~H"""
    <div class="space-y-3">
      <div class="flex items-center gap-3 bg-base-100 rounded-lg p-3 shadow-sm">
        <span class="badge badge-warning badge-sm">Open</span>
        <div class="flex-1 h-2 bg-base-content/10 rounded w-3/4"></div>
      </div>
      
      <div class="flex items-center gap-3 bg-base-100 rounded-lg p-3 shadow-sm">
        <span class="badge badge-info badge-sm">Pending</span>
        <div class="flex-1 h-2 bg-base-content/10 rounded w-2/3"></div>
      </div>
      
      <div class="flex items-center gap-3 bg-base-100 rounded-lg p-3 shadow-sm">
        <span class="badge badge-success badge-sm">Solved</span>
        <div class="flex-1 h-2 bg-base-content/10 rounded w-1/2"></div>
      </div>
    </div>
    """
  end

  defp template_preview(%{template: "project"} = assigns) do
    ~H"""
    <div class="space-y-3">
      <div class="flex items-center gap-2">
        <div class="w-6 h-6 rounded bg-base-content/10"></div>
        
        <div class="flex-1 h-3 bg-base-content/20 rounded-full"></div>
      </div>
      
      <div class="flex items-center gap-2 ml-4">
        <div class="w-5 h-5 rounded bg-base-content/10"></div>
        
        <div class="flex-1 h-2 bg-base-content/15 rounded-full w-2/3"></div>
      </div>
      
      <div class="flex items-center gap-2 ml-4">
        <div class="w-5 h-5 rounded bg-base-content/10"></div>
        
        <div class="flex-1 h-2 bg-base-content/15 rounded-full w-1/2"></div>
      </div>
    </div>
    """
  end

  defp template_preview(assigns) do
    ~H"""
    <div class="flex items-center justify-center h-full text-base-content/40">
      Preview not available
    </div>
    """
  end
end
