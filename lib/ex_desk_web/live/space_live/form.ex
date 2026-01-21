defmodule ExDeskWeb.SpaceLive.Form do
  use ExDeskWeb, :live_view

  alias ExDesk.Support
  alias ExDesk.Support.Space

  @template_info %{
    "kanban" => %{name: "Kanban", color: "#22C55E"},
    "service_desk" => %{name: "Service Desk", color: "#F97316"},
    "project" => %{name: "Project", color: "#3B82F6"}
  }

  @impl true
  def mount(params, _session, socket) do
    {action, space, template} = resolve_action(params)

    changeset = Support.change_space(space)

    {:ok,
     socket
     |> assign(:action, action)
     |> assign(:space, space)
     |> assign(:template, template)
     |> assign(
       :template_info,
       Map.get(@template_info, template, %{name: "Custom", color: "#6B7280"})
     )
     |> assign(:page_title, page_title(action))
     |> assign(:form, to_form(changeset))}
  end

  defp resolve_action(%{"key" => key}) do
    space = Support.get_space_by_key!(key)
    {:edit, space, Atom.to_string(space.template)}
  end

  defp resolve_action(%{"template" => template}) do
    {:new, %Space{template: String.to_existing_atom(template)}, template}
  end

  defp page_title(:new), do: "New Space"
  defp page_title(:edit), do: "Edit Space"

  @impl true
  def handle_event("validate", %{"space" => space_params}, socket) do
    changeset =
      socket.assigns.space
      |> Support.change_space(space_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"space" => space_params}, socket) do
    save_space(socket, socket.assigns.action, space_params)
  end

  defp save_space(socket, :new, space_params) do
    space_params = Map.put(space_params, "template", socket.assigns.template)

    case Support.create_space(space_params) do
      {:ok, space} ->
        {:noreply,
         socket
         |> put_flash(:info, "Space created successfully")
         |> push_navigate(to: ~p"/spaces/#{space.key}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_space(socket, :edit, space_params) do
    case Support.update_space(socket.assigns.space, space_params) do
      {:ok, space} ->
        {:noreply,
         socket
         |> put_flash(:info, "Space updated successfully")
         |> push_navigate(to: ~p"/spaces/#{space.key}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-2xl mx-auto">
        <div class="mb-8">
          <.link
            navigate={back_path(@action, @space)}
            class="text-base-content/60 hover:text-base-content flex items-center gap-1 mb-4"
          >
            <.icon name="hero-arrow-left" class="size-4" /> Back
          </.link>
          <div class="flex items-center gap-4">
            <div
              class="size-12 rounded-xl flex items-center justify-center"
              style={"background-color: #{@template_info.color}"}
            >
              <.icon name="hero-rectangle-stack" class="size-6 text-white" />
            </div>
            
            <div>
              <h1 class="text-2xl font-bold">{@page_title}</h1>
              
              <p class="text-base-content/60">{@template_info.name} template</p>
            </div>
          </div>
        </div>
        
        <.form
          for={@form}
          id="space-form"
          phx-change="validate"
          phx-submit="save"
          class="space-y-6"
        >
          <div class="card bg-base-200">
            <div class="card-body space-y-4">
              <.input
                field={@form[:name]}
                type="text"
                label="Space name"
                placeholder="e.g., IT Support, HR Requests"
                required
              />
              <.input
                field={@form[:key]}
                type="text"
                label="Space key"
                placeholder="e.g., IT, HR, FAC"
                class="uppercase"
                required
              />
              <.input
                field={@form[:color]}
                type="color"
                label="Color"
                value={@form[:color].value || @template_info.color}
              />
              <.input
                field={@form[:description]}
                type="textarea"
                label="Description"
                placeholder="What is this space for?"
                rows="3"
              />
            </div>
          </div>
          
          <div class="flex justify-end gap-3">
            <.link navigate={back_path(@action, @space)} class="btn btn-ghost">Cancel</.link>
            <button type="submit" class="btn btn-primary">
              {if @action == :new, do: "Create Space", else: "Save Changes"}
            </button>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  defp back_path(:new, _space), do: ~p"/spaces/new"
  defp back_path(:edit, space), do: ~p"/spaces/#{space.key}"
end
