defmodule ExDeskWeb.SpaceLive.Index do
  use ExDeskWeb, :live_view

  alias ExDesk.Support

  @impl true
  def mount(_params, _session, socket) do
    spaces = Support.list_spaces()

    {:ok,
     socket
     |> assign(:page_title, "Spaces")
     |> assign(:spaces, spaces)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    space = Support.get_space!(id)
    {:ok, _} = Support.delete_space(space)

    {:noreply, assign(socket, :spaces, Support.list_spaces())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} spaces={@spaces}>
      <div class="space-y-6">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl font-bold">Spaces</h1>

            <p class="text-base-content/60">Organize your work into dedicated spaces</p>
          </div>

          <.link
            navigate={~p"/spaces/new"}
            class="btn btn-primary"
          >
            <.icon name="hero-plus" class="size-5" /> New Space
          </.link>
        </div>

        <%= if @spaces == [] do %>
          <div class="card bg-base-200 p-12 text-center">
            <div class="mx-auto max-w-sm">
              <.icon name="hero-rectangle-stack" class="size-16 mx-auto text-base-content/30 mb-4" />
              <h3 class="text-lg font-semibold mb-2">No spaces yet</h3>

              <p class="text-base-content/60 mb-6">
                Create your first space to start organizing your work
              </p>

              <.link navigate={~p"/spaces/new"} class="btn btn-primary">
                Create your first space
              </.link>
            </div>
          </div>
        <% else %>
          <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            <div
              :for={space <- @spaces}
              id={"space-#{space.id}"}
              class="card bg-base-200 hover:bg-base-300 transition-colors"
            >
              <div class="card-body">
                <div class="flex items-start gap-3">
                  <div
                    class="size-10 rounded-lg flex-shrink-0"
                    style={"background-color: #{space.color}"}
                  />
                  <div class="flex-1 min-w-0">
                    <.link navigate={~p"/spaces/#{space.key}"} class="hover:underline">
                      <h3 class="font-semibold truncate">{space.name}</h3>
                    </.link>
                    <p class="text-sm text-base-content/60">{space.key}</p>
                  </div>
                </div>

                <p :if={space.description} class="text-sm text-base-content/70 mt-2 line-clamp-2">
                  {space.description}
                </p>

                <div class="card-actions justify-end mt-4">
                  <.link navigate={~p"/spaces/#{space.key}/edit"} class="btn btn-ghost btn-sm">
                    Edit
                  </.link>
                  <button
                    phx-click="delete"
                    phx-value-id={space.id}
                    data-confirm="Are you sure you want to delete this space?"
                    class="btn btn-ghost btn-sm text-error"
                  >
                    Delete
                  </button>
                </div>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
