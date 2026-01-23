defmodule ExDeskWeb.SpaceLive.Show do
  use ExDeskWeb, :live_view

  alias ExDesk.Support

  @impl true
  def mount(%{"key" => key}, _session, socket) do
    space = Support.get_space_by_key!(key)
    ticket_count = Support.count_tickets_by_space(space)

    {:ok,
     socket
     |> assign(:page_title, space.name)
     |> assign(:space, space)
     |> assign(:ticket_count, ticket_count)}
  end

  @impl true
  @spec handle_event(<<_::48>>, any(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event("delete", _params, socket) do
    space = socket.assigns.space
    {:ok, _} = Support.delete_space(space)

    {:noreply,
     socket
     |> put_flash(:info, "Space deleted successfully")
     |> push_navigate(to: ~p"/spaces")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-4xl mx-auto space-y-6">
        <%!-- Header --%>
        <div class="flex items-start justify-between">
          <div class="flex items-center gap-4">
            <div
              class="size-16 rounded-xl flex items-center justify-center"
              style={"background-color: #{@space.color}"}
            >
              <.icon name="hero-rectangle-stack" class="size-8 text-white" />
            </div>

            <div>
              <h1 class="text-3xl font-bold">{@space.name}</h1>

              <p class="text-base-content/60">{@space.key} · {template_label(@space.template)}</p>
            </div>
          </div>

          <div class="flex gap-2">
            <.link navigate={~p"/spaces/#{@space.key}/edit"} class="btn btn-ghost">
              <.icon name="hero-pencil" class="size-4" /> Edit
            </.link>
            <button
              phx-click="delete"
              data-confirm="Are you sure you want to delete this space? This action cannot be undone."
              class="btn btn-ghost text-error"
            >
              <.icon name="hero-trash" class="size-4" /> Delete
            </button>
          </div>
        </div>
        <%!-- Description --%>
        <div :if={@space.description} class="card bg-base-200">
          <div class="card-body">
            <h3 class="font-semibold mb-2">Description</h3>

            <p class="text-base-content/70">{@space.description}</p>
          </div>
        </div>
        <%!-- Stats --%>
        <div class="grid gap-4 md:grid-cols-3">
          <div class="card bg-base-200">
            <div class="card-body">
              <div class="text-sm text-base-content/60">Tickets</div>

              <div class="text-2xl font-bold">{@ticket_count}</div>
            </div>
          </div>

          <div class="card bg-base-200">
            <div class="card-body">
              <div class="text-sm text-base-content/60">Template</div>

              <div class="text-2xl font-bold">{template_label(@space.template)}</div>
            </div>
          </div>

          <div class="card bg-base-200">
            <div class="card-body">
              <div class="text-sm text-base-content/60">Created</div>

              <div class="text-2xl font-bold">{Calendar.strftime(@space.inserted_at, "%b %d")}</div>
            </div>
          </div>
        </div>
        <%!-- Actions --%>
        <div class="flex gap-3">
          <.link navigate={~p"/spaces"} class="btn btn-ghost">
            <.icon name="hero-arrow-left" class="size-4" /> Back to Spaces
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp template_label(:kanban), do: "Kanban"
  defp template_label(:service_desk), do: "Service Desk"
  defp template_label(:project), do: "Project"
  defp template_label(_), do: "Custom"
end
