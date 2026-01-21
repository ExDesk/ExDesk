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
           <%!-- Live Preview Column --%> <%!-- Live Preview Column --%>
          <div class="lg:col-span-1" id="live-preview">
            <div class="mockup-window border border-base-300 bg-base-300 shadow-xl overflow-hidden transform transition-all duration-300 hover:shadow-2xl">
              <div class="border-b border-base-300 bg-base-200 flex items-center px-4 py-3 gap-2">
                <div class="w-2.5 h-2.5 rounded-full bg-error/50"></div>
                
                <div class="w-2.5 h-2.5 rounded-full bg-warning/50"></div>
                
                <div class="w-2.5 h-2.5 rounded-full bg-success/50"></div>
                
                <div class="ml-2 w-full max-w-[150px] h-4 rounded-md bg-base-300/50"></div>
              </div>
              
              <div class="bg-base-100 p-0 h-[400px] overflow-hidden relative group">
                <!-- Sidebar / App Chrome Mock -->
                <div class="absolute left-0 top-0 bottom-0 w-12 bg-base-200 border-r border-base-300 flex flex-col items-center py-4 gap-3 z-10">
                  <div class="w-6 h-6 rounded bg-primary/20"></div>
                  
                  <div class="w-6 h-6 rounded-lg bg-base-300 mt-2"></div>
                  
                  <div class="w-6 h-6 rounded-lg bg-base-300"></div>
                  
                  <div class="w-6 h-6 rounded-lg bg-base-300"></div>
                </div>
                <!-- Main Content Area -->
                <div class="pl-12 h-full flex flex-col">
                  <!-- Header -->
                  <div class="h-12 border-b border-base-300 flex items-center px-4 justify-between bg-base-100">
                    <div class="w-24 h-3 rounded bg-base-200"></div>
                    
                    <div class="flex gap-2">
                      <div class="size-6 rounded-full bg-base-200"></div>
                    </div>
                  </div>
                  <!-- Canvas -->
                  <div class="p-4 bg-base-50/50 flex-1 overflow-hidden relative">
                    <.template_preview template={@selected_template.id} />
                  </div>
                </div>
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
    <div class="grid grid-cols-3 gap-2 h-full content-start opacity-80 group-hover:opacity-100 transition-opacity">
      <!-- To Do Column -->
      <div class="flex flex-col gap-2">
        <div class="flex items-center justify-between mb-1">
          <span class="text-[9px] font-bold uppercase tracking-wider text-base-content/40">
            To Do
          </span>
        </div>
        
        <div class="card bg-base-100 shadow-sm border border-base-200 p-2 space-y-2">
          <div class="w-3/4 h-1.5 bg-base-content/10 rounded"></div>
          
          <div class="w-1/2 h-1.5 bg-base-content/10 rounded"></div>
          
          <div class="flex justify-between items-center mt-1 pt-1 border-t border-base-100">
            <div class="size-3 rounded-full bg-primary/20"></div>
          </div>
        </div>
        
        <div class="card bg-base-100 shadow-sm border border-base-200 p-2 space-y-2">
          <div class="w-full h-1.5 bg-base-content/10 rounded"></div>
          
          <div class="flex justify-between items-center mt-1">
            <div class="size-3 rounded-full bg-secondary/20"></div>
            
            <div class="w-6 h-1 bg-base-content/10 rounded"></div>
          </div>
        </div>
        
        <div class="card bg-base-100 shadow-sm border border-base-200 p-2 space-y-2 opacity-50">
          <div class="w-2/3 h-1.5 bg-base-content/10 rounded"></div>
        </div>
      </div>
      <!-- Doing Column -->
      <div class="flex flex-col gap-2">
        <div class="flex items-center justify-between mb-1">
          <span class="text-[9px] font-bold uppercase tracking-wider text-base-content/40">
            Doing
          </span>
        </div>
        
        <div class="card bg-base-100 shadow-sm border border-base-200 p-2 space-y-2 border-l-2 border-l-primary">
          <div class="w-full h-1.5 bg-base-content/10 rounded"></div>
          
          <div class="w-3/4 h-1.5 bg-base-content/10 rounded"></div>
          
          <div class="w-full h-16 bg-base-200/50 rounded flex items-center justify-center text-[8px] text-base-content/30">
            Image
          </div>
          
          <div class="flex justify-between items-center mt-1">
            <div class="flex -space-x-1">
              <div class="size-3 rounded-full bg-primary/20 ring-1 ring-base-100"></div>
              
              <div class="size-3 rounded-full bg-secondary/20 ring-1 ring-base-100"></div>
            </div>
          </div>
        </div>
      </div>
      <!-- Done Column -->
      <div class="flex flex-col gap-2">
        <div class="flex items-center justify-between mb-1">
          <span class="text-[9px] font-bold uppercase tracking-wider text-base-content/40">Done</span>
        </div>
        
        <div class="card bg-base-100 shadow-sm border border-base-200 p-2 space-y-2 opacity-60">
          <div class="flex items-center gap-1">
            <div class="size-3 rounded-full border border-success text-success flex items-center justify-center text-[8px]">
              ✓
            </div>
            
            <div class="w-3/4 h-1.5 bg-base-content/10 rounded relative top-[1px]"></div>
          </div>
        </div>
        
        <div class="card bg-base-100 shadow-sm border border-base-200 p-2 space-y-2 opacity-60">
          <div class="flex items-center gap-1">
            <div class="size-3 rounded-full border border-success text-success flex items-center justify-center text-[8px]">
              ✓
            </div>
            
            <div class="w-1/2 h-1.5 bg-base-content/10 rounded relative top-[1px]"></div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp template_preview(%{template: "service_desk"} = assigns) do
    ~H"""
    <div class="border border-base-200 rounded-lg overflow-hidden bg-base-100 shadow-sm opacity-80 group-hover:opacity-100 transition-opacity">
      <div class="grid grid-cols-12 gap-2 bg-base-200/50 px-3 py-2 text-[8px] font-bold text-base-content/40 border-b border-base-200 uppercase tracking-wider">
        <div class="col-span-2">ID</div>
        
        <div class="col-span-7">Subject</div>
        
        <div class="col-span-3 text-right">Status</div>
      </div>
      
      <div class="px-3 py-2 grid grid-cols-12 gap-2 items-center border-b border-base-100 last:border-0 hover:bg-base-50 transition-colors">
        <div class="col-span-2 text-[9px] font-mono text-base-content/60">#1294</div>
        
        <div class="col-span-7">
          <div class="w-3/4 h-1.5 bg-base-content/10 rounded"></div>
        </div>
        
        <div class="col-span-3 flex justify-end">
          <div class="px-1.5 py-0.5 rounded bg-error/10 text-error text-[8px] font-medium border border-error/20">
            High
          </div>
        </div>
      </div>
      
      <div class="px-3 py-2 grid grid-cols-12 gap-2 items-center border-b border-base-100 last:border-0 hover:bg-base-50 transition-colors">
        <div class="col-span-2 text-[9px] font-mono text-base-content/60">#1293</div>
        
        <div class="col-span-7 space-y-1">
          <div class="w-1/2 h-1.5 bg-base-content/10 rounded"></div>
          
          <div class="w-full h-1 bg-base-content/5 rounded"></div>
        </div>
        
        <div class="col-span-3 flex justify-end">
          <div class="px-1.5 py-0.5 rounded bg-warning/10 text-warning text-[8px] font-medium border border-warning/20">
            Medium
          </div>
        </div>
      </div>
      
      <div class="px-3 py-2 grid grid-cols-12 gap-2 items-center border-b border-base-100 last:border-0 hover:bg-base-50 transition-colors">
        <div class="col-span-2 text-[9px] font-mono text-base-content/60">#1292</div>
        
        <div class="col-span-7">
          <div class="w-2/3 h-1.5 bg-base-content/10 rounded"></div>
        </div>
        
        <div class="col-span-3 flex justify-end">
          <div class="px-1.5 py-0.5 rounded bg-success/10 text-success text-[8px] font-medium border border-success/20">
            Solved
          </div>
        </div>
      </div>
      
      <div class="px-3 py-2 grid grid-cols-12 gap-2 items-center border-b border-base-100 last:border-0 hover:bg-base-50 transition-colors">
        <div class="col-span-2 text-[9px] font-mono text-base-content/60">#1291</div>
        
        <div class="col-span-7">
          <div class="w-1/2 h-1.5 bg-base-content/10 rounded"></div>
        </div>
        
        <div class="col-span-3 flex justify-end">
          <div class="px-1.5 py-0.5 rounded bg-base-200 text-base-content/60 text-[8px] font-medium border border-base-300">
            Closed
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp template_preview(%{template: "project"} = assigns) do
    ~H"""
    <div class="space-y-5 opacity-80 group-hover:opacity-100 transition-opacity">
      <!-- Roadmap Header -->
      <div class="flex gap-4 border-b border-base-200 pb-2">
        <div class="flex-1 space-y-1">
          <div class="flex justify-between items-center text-[9px] font-bold text-base-content/40 uppercase tracking-wider">
            <span>Q1 2024</span> <span>Q2 2024</span>
          </div>
          
          <div class="flex gap-1 h-1">
            <div class="w-1/6 bg-transparent"></div>
            
            <div class="flex-1 bg-base-200 rounded-full overflow-hidden">
              <div class="h-full w-1/3 bg-primary/20"></div>
            </div>
          </div>
        </div>
      </div>
      <!-- Feature 1 -->
      <div class="space-y-2">
        <div class="flex items-center gap-3">
          <div class="size-2 rounded bg-primary shadow-sm shadow-primary/50"></div>
          
          <div class="flex-1">
            <div class="w-1/3 h-1.5 bg-base-content/10 rounded mb-1"></div>
            
            <div class="w-full h-1 bg-base-200 rounded-full overflow-hidden">
              <div class="w-2/3 h-full bg-primary/60"></div>
            </div>
          </div>
          
          <div class="text-[9px] text-base-content/40 font-mono">65%</div>
        </div>
      </div>
      <!-- Feature 2 -->
      <div class="space-y-2 pl-4 border-l border-base-200">
        <div class="flex items-center gap-3">
          <div class="size-1.5 rounded bg-secondary/70"></div>
          
          <div class="flex-1">
            <div class="w-1/4 h-1.5 bg-base-content/10 rounded mb-1"></div>
            
            <div class="w-full h-1 bg-base-200 rounded-full overflow-hidden">
              <div class="w-1/3 h-full bg-secondary/50"></div>
            </div>
          </div>
          
          <div class="text-[9px] text-base-content/40 font-mono">30%</div>
        </div>
        
        <div class="flex items-center gap-3">
          <div class="size-1.5 rounded bg-base-content/30"></div>
          
          <div class="flex-1">
            <div class="w-1/5 h-1.5 bg-base-content/10 rounded mb-1"></div>
            
            <div class="w-full h-1 bg-base-200 rounded-full"></div>
          </div>
          
          <div class="text-[9px] text-base-content/40 font-mono">0%</div>
        </div>
      </div>
      <!-- Feature 3 -->
      <div class="space-y-2">
        <div class="flex items-center gap-3">
          <div class="size-2 rounded bg-accent shadow-sm shadow-accent/50"></div>
          
          <div class="flex-1">
            <div class="w-1/2 h-1.5 bg-base-content/10 rounded mb-1"></div>
            
            <div class="w-full h-1 bg-base-200 rounded-full overflow-hidden">
              <div class="w-[90%] h-full bg-accent/50"></div>
            </div>
          </div>
          
          <div class="text-[9px] text-base-content/40 font-mono">90%</div>
        </div>
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
