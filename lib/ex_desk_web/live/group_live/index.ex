defmodule ExDeskWeb.GroupLive.Index do
  use ExDeskWeb, :live_view

  import ExDeskWeb.Authorization, only: [can?: 2, can?: 3]

  alias ExDesk.Support
  alias ExDesk.Support.Group

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    if can?(user, :list_groups) do
      groups = Support.list_groups()

      {:ok,
       socket
       |> assign(:groups, groups)
       |> assign(:group, nil)
       |> assign(:form, nil)
       |> assign(:patch, ~p"/groups")
       |> assign(:page_title, "Groups")}
    else
      {:ok,
       socket
       |> put_flash(:error, "You are not authorized to access this page.")
       |> redirect(to: ~p"/dashboard")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Groups")
    |> assign(:group, nil)
    |> assign(:form, nil)
    |> assign(:patch, ~p"/groups")
  end

  defp apply_action(socket, :new, _params) do
    user = socket.assigns.current_scope.user

    if can?(user, :create_group) do
      group = %Group{}
      changeset = Group.changeset(group, %{})

      socket
      |> assign(:page_title, "New Group")
      |> assign(:group, group)
      |> assign(:form, to_form(changeset))
      |> assign(:patch, ~p"/groups")
    else
      socket
      |> put_flash(:error, "You are not authorized to create groups.")
      |> push_navigate(to: ~p"/groups")
    end
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    group = Support.get_group!(id)
    user = socket.assigns.current_scope.user

    if can?(user, :update_group, group) do
      changeset = Group.changeset(group, %{})

      socket
      |> assign(:page_title, "Edit Group")
      |> assign(:group, group)
      |> assign(:form, to_form(changeset))
      |> assign(:patch, ~p"/groups")
    else
      socket
      |> put_flash(:error, "You are not authorized to edit groups.")
      |> push_navigate(to: ~p"/groups")
    end
  end

  @impl true
  def handle_event("validate", %{"group" => group_params}, socket) do
    group = socket.assigns.group || %Group{}
    changeset = group |> Group.changeset(group_params) |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"group" => group_params}, socket) do
    user = socket.assigns.current_scope.user

    case socket.assigns.live_action do
      :new ->
        if can?(user, :create_group) do
          case Support.create_group(group_params) do
            {:ok, _group} ->
              {:noreply,
               socket
               |> put_flash(:info, "Group created successfully")
               |> assign(:groups, Support.list_groups())
               |> push_patch(to: ~p"/groups")}

            {:error, %Ecto.Changeset{} = changeset} ->
              {:noreply, assign(socket, :form, to_form(changeset))}
          end
        else
          {:noreply,
           socket
           |> put_flash(:error, "You are not authorized to create groups.")
           |> push_navigate(to: ~p"/groups")}
        end

      :edit ->
        group = socket.assigns.group

        if can?(user, :update_group, group) do
          case Support.update_group(group, group_params) do
            {:ok, _group} ->
              {:noreply,
               socket
               |> put_flash(:info, "Group updated successfully")
               |> assign(:groups, Support.list_groups())
               |> push_patch(to: ~p"/groups")}

            {:error, %Ecto.Changeset{} = changeset} ->
              {:noreply, assign(socket, :form, to_form(changeset))}
          end
        else
          {:noreply,
           socket
           |> put_flash(:error, "You are not authorized to edit groups.")
           |> push_navigate(to: ~p"/groups")}
        end
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = socket.assigns.current_scope.user
    group = Support.get_group!(id)

    if can?(user, :delete_group, group) do
      {:ok, _} = Support.delete_group(group)

      {:noreply,
       socket
       |> put_flash(:info, "Group deleted successfully")
       |> assign(:groups, Support.list_groups())}
    else
      {:noreply, put_flash(socket, :error, "You are not authorized to delete groups.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} spaces={@spaces}>
      <%= if @live_action in [:new, :edit] do %>
        <div class="max-w-3xl mx-auto space-y-6">
          <div class="flex items-center justify-between">
            <.link navigate={@patch} class="btn btn-ghost btn-sm">
              <.icon name="hero-arrow-left" class="size-4" /> Back
            </.link>
          </div>

          <section class="bg-base-100 rounded-box border border-base-300 shadow-sm p-6">
            <div class="mb-4">
              <h1 class="text-2xl font-bold">{@page_title}</h1>
              <p class="text-base-content/60">Organize tickets by team and routing queue.</p>
            </div>

            <.form
              for={@form}
              id="group-form"
              phx-change="validate"
              phx-submit="save"
              class="space-y-6"
            >
              <.input
                field={@form[:name]}
                type="text"
                label="Name"
                placeholder="e.g., IT, Facilities, Tier 2"
                required
              />

              <.input
                field={@form[:description]}
                type="textarea"
                label="Description"
                placeholder="When should tickets be routed here?"
                rows="3"
              />

              <div class="flex items-center justify-end gap-3 pt-2">
                <.link navigate={@patch} class="btn btn-ghost">Cancel</.link>
                <button type="submit" class="btn btn-primary">Save</button>
              </div>
            </.form>
          </section>
        </div>
      <% else %>
        <div class="max-w-6xl mx-auto space-y-6">
          <div class="flex items-end justify-between gap-4">
            <div>
              <h1 class="text-2xl md:text-3xl font-bold">Groups</h1>
              <p class="text-base-content/60">Teams and queues used to route tickets.</p>
            </div>

            <.link
              :if={can?(@current_scope.user, :create_group)}
              navigate={~p"/groups/new"}
              class="btn btn-primary"
            >
              <.icon name="hero-plus" class="size-4" /> New Group
            </.link>
          </div>

          <%= if @groups == [] do %>
            <div class="card bg-base-200 p-12 text-center">
              <div class="mx-auto max-w-sm">
                <.icon name="hero-user-group" class="size-16 mx-auto text-base-content/30 mb-4" />
                <h3 class="text-lg font-semibold mb-2">No groups yet</h3>
                <p class="text-base-content/60 mb-6">
                  Create a group to start routing tickets by team.
                </p>
                <.link
                  :if={can?(@current_scope.user, :create_group)}
                  navigate={~p"/groups/new"}
                  class="btn btn-primary"
                >
                  Create your first group
                </.link>
              </div>
            </div>
          <% else %>
            <div class="bg-base-100 rounded-box border border-base-300 shadow-sm overflow-hidden">
              <.table id="groups-table" rows={@groups} row_id={fn g -> "group-#{g.id}" end}>
                <:col :let={group} label="Name">
                  <span class="font-semibold">{group.name}</span>
                </:col>

                <:col :let={group} label="Description">
                  <span class="text-base-content/70">{group.description}</span>
                </:col>

                <:action :let={group}>
                  <.link
                    :if={can?(@current_scope.user, :update_group, group)}
                    navigate={~p"/groups/#{group.id}/edit"}
                    class="link"
                  >
                    Edit
                  </.link>

                  <button
                    :if={can?(@current_scope.user, :delete_group, group)}
                    type="button"
                    phx-click="delete"
                    phx-value-id={group.id}
                    data-confirm="Are you sure you want to delete this group?"
                    class="link text-error"
                  >
                    Delete
                  </button>
                </:action>
              </.table>
            </div>
          <% end %>
        </div>
      <% end %>
    </Layouts.app>
    """
  end
end
