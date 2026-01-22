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
    suggestions = generate_key_suggestions(space.name || "")

    {:ok,
     socket
     |> assign(:action, action)
     |> assign(:space, space)
     |> assign(:template, template)
     |> assign(:key_suggestions, suggestions)
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
    template_atom =
      Map.get(
        %{"kanban" => :kanban, "service_desk" => :service_desk, "project" => :project},
        template,
        :kanban
      )

    {:new, %Space{template: template_atom}, template}
  end

  defp page_title(:new), do: "New Space"
  defp page_title(:edit), do: "Edit Space"

  @impl true
  def handle_event("validate", %{"space" => space_params}, socket) do
    changeset =
      socket.assigns.space
      |> Support.change_space(space_params)
      |> Map.put(:action, :validate)

    suggestions = generate_key_suggestions(space_params["name"] || "")

    current_key = space_params["key"]

    suggestions =
      if current_key && current_key != "" && current_key not in suggestions,
        do: [current_key | suggestions],
        else: suggestions

    {:noreply,
     socket
     |> assign(:form, to_form(changeset))
     |> assign(:key_suggestions, suggestions)}
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
              <div class="fieldset mb-2">
                <label>
                  <span class="label mb-1 font-semibold">Space key</span>
                  <select
                    id={@form[:key].id}
                    name={@form[:key].name}
                    class="select select-bordered w-full uppercase"
                    required
                  >
                    <option
                      value=""
                      disabled
                      selected={is_nil(@form[:key].value) || @form[:key].value == ""}
                    >
                      Select a key
                    </option>
                    <option
                      :for={suggestion <- @key_suggestions}
                      value={suggestion}
                      selected={to_string(@form[:key].value) == suggestion}
                    >
                      {suggestion}
                    </option>
                  </select>
                </label>
                <p
                  :if={@form[:key].errors != []}
                  class="mt-1.5 flex gap-2 items-center text-sm text-error"
                >
                  <.icon name="hero-exclamation-circle" class="size-5" />
                  {Enum.map(@form[:key].errors, fn {msg, _} -> msg end) |> Enum.join(", ")}
                </p>
              </div>
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

  # Gera sugestões de key baseadas no nome do space
  defp generate_key_suggestions(name) when is_binary(name) and byte_size(name) > 0 do
    words = String.split(name, ~r/\s+/, trim: true)

    suggestions =
      [
        # Iniciais de cada palavra (IT Support → ITS)
        words |> Enum.map(&String.first/1) |> Enum.join(),
        # Primeira palavra truncada (Support → SUP)
        words |> List.first() |> String.slice(0, 3),
        # Duas primeiras letras de cada palavra (IT Support → ITSU)
        words |> Enum.take(2) |> Enum.map(&String.slice(&1, 0, 2)) |> Enum.join(),
        # Primeira palavra inteira se pequena
        if(length(words) == 1 and String.length(List.first(words)) <= 4,
          do: List.first(words),
          else: nil
        )
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&String.upcase/1)
      |> Enum.filter(&(String.length(&1) >= 2 and String.length(&1) <= 10))
      |> Enum.filter(&String.match?(&1, ~r/^[A-Z]+$/))

    suggestions =
      suggestions
      |> Enum.uniq()
      |> Enum.take(3)

    if suggestions == [], do: ["SD", "PROJ", "KB"], else: suggestions
  end

  defp generate_key_suggestions(_), do: ["SD", "PROJ", "KB"]
end
