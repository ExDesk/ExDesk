defmodule ExDeskWeb.SpaceLive.Show do
  use ExDeskWeb, :live_view

  alias ExDesk.Accounts
  alias ExDesk.Support
  alias Phoenix.LiveView.JS

  @impl true
  def mount(%{"key" => key}, _session, socket) do
    space = Support.get_space_by_key!(key)
    ticket_count = Support.count_tickets_by_space(space)

    show_assignee? = can?(socket.assigns.current_scope.user, :assign_ticket)

    assignee_options =
      if show_assignee? do
        Accounts.list_agents()
        |> Enum.map(fn u -> {u.email, u.id} end)
      else
        []
      end

    socket =
      socket
      |> assign(:page_title, space.name)
      |> assign(:space, space)
      |> assign(:ticket_count, ticket_count)
      |> assign(:show_new_ticket_modal?, false)
      |> assign(:new_ticket_form, new_ticket_form())
      |> assign(:show_assignee?, show_assignee?)
      |> assign(:assignee_options, assignee_options)

    socket =
      if space.template == :kanban do
        assign_kanban(socket, space)
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("delete", _params, socket) do
    space = socket.assigns.space

    if can?(socket.assigns.current_scope.user, :delete_space, space) do
      {:ok, _} = Support.delete_space(space)

      {:noreply,
       socket
       |> put_flash(:info, "Space deleted successfully")
       |> push_navigate(to: ~p"/spaces")}
    else
      {:noreply, put_flash(socket, :error, "You are not authorized to delete this space.")}
    end
  end

  @impl true
  def handle_event("open_new_ticket_modal", _params, socket) do
    {:noreply, assign(socket, :show_new_ticket_modal?, true)}
  end

  @impl true
  def handle_event("close_new_ticket_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_new_ticket_modal?, false)
     |> assign(:new_ticket_form, new_ticket_form())}
  end

  @impl true
  def handle_event("validate_new_ticket", %{"ticket" => ticket_params}, socket) do
    ticket_params = sanitize_new_ticket_params(socket, ticket_params)

    changeset =
      %Support.Ticket{}
      |> Support.Ticket.create_changeset(ticket_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :new_ticket_form, to_form(changeset))}
  end

  @impl true
  def handle_event("create_new_ticket", %{"ticket" => ticket_params}, socket) do
    space = socket.assigns.space
    actor_id = socket.assigns.current_scope.user.id
    ticket_params = sanitize_new_ticket_params(socket, ticket_params)

    case Support.create_ticket_in_space(space.id, ticket_params, actor_id) do
      {:ok, _ticket} ->
        socket =
          if space.template == :kanban do
            assign_kanban(socket, space)
          else
            socket
          end

        {:noreply,
         socket
         |> assign(:show_new_ticket_modal?, false)
         |> assign(:new_ticket_form, new_ticket_form())
         |> put_flash(:info, "Ticket created successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :new_ticket_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event(
        "kanban_drop",
        %{
          "ticket_id" => ticket_id,
          "from_column" => from_column,
          "to_column" => to_column,
          "from_ordered_ids" => from_ordered_ids,
          "to_ordered_ids" => to_ordered_ids
        },
        socket
      ) do
    space = socket.assigns.space
    actor_id = socket.assigns.current_scope.user.id

    result =
      Support.move_ticket_on_kanban_board(
        space.id,
        String.to_integer(ticket_id),
        from_column,
        to_column,
        from_ordered_ids,
        to_ordered_ids,
        actor_id
      )

    case result do
      {:ok, _ticket} ->
        {:noreply, assign_kanban(socket, space)}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not move ticket: #{inspect(reason)}")
         |> assign_kanban(space)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} spaces={@spaces}>
      <%= if @space.template == :kanban do %>
        <div class="mx-auto max-w-7xl space-y-6">
          <div class="flex items-start justify-between gap-4">
            <div class="flex items-center gap-4 min-w-0">
              <div
                class="size-14 rounded-xl flex items-center justify-center flex-shrink-0 shadow-sm"
                style={"background-color: #{@space.color}"}
              >
                <.icon name="hero-rectangle-stack" class="size-7 text-white" />
              </div>

              <div class="min-w-0">
                <h1 class="text-2xl md:text-3xl font-bold truncate">{@space.name}</h1>
                <p class="text-base-content/60">{@space.key} · Kanban · {@ticket_count} tickets</p>
              </div>
            </div>

            <div class="flex items-center gap-2 flex-shrink-0">
              <button
                id="space-new-ticket"
                phx-click="open_new_ticket_modal"
                class="btn btn-primary btn-sm"
              >
                <.icon name="hero-plus" class="size-4" /> New ticket
              </button>

              <.link
                :if={can?(@current_scope.user, :update_space, @space)}
                navigate={~p"/spaces/#{@space.key}/edit"}
                class="btn btn-ghost btn-sm"
              >
                <.icon name="hero-pencil" class="size-4" /> Edit
              </.link>

              <button
                :if={can?(@current_scope.user, :delete_space, @space)}
                phx-click="delete"
                data-confirm="Are you sure you want to delete this space? This action cannot be undone."
                class="btn btn-ghost btn-sm text-error"
              >
                <.icon name="hero-trash" class="size-4" /> Delete
              </button>
            </div>
          </div>

          <div
            id="kanban-board"
            phx-hook="KanbanDnD"
            class="flex gap-4 overflow-x-auto pb-2 -mx-4 px-4 lg:mx-0 lg:px-0 scroll-px-4"
          >
            <.kanban_column
              id="kanban-col-todo"
              column="todo"
              title="To Do"
              count={@todo_count}
              list_id="kanban-todo-tickets"
              tickets_stream={@streams.todo_tickets}
              return_to={~p"/spaces/#{@space.key}"}
            />

            <.kanban_column
              id="kanban-col-doing"
              column="doing"
              title="In progress"
              count={@doing_count}
              list_id="kanban-doing-tickets"
              tickets_stream={@streams.doing_tickets}
              return_to={~p"/spaces/#{@space.key}"}
            />

            <.kanban_column
              id="kanban-col-done"
              column="done"
              title="Done"
              count={@done_count}
              list_id="kanban-done-tickets"
              tickets_stream={@streams.done_tickets}
              return_to={~p"/spaces/#{@space.key}"}
            />
          </div>

          <div class="flex gap-3">
            <.link navigate={~p"/spaces"} class="btn btn-ghost btn-sm">
              <.icon name="hero-arrow-left" class="size-4" /> Back to Spaces
            </.link>
          </div>
        </div>

        <.modal
          :if={@show_new_ticket_modal?}
          id="space-ticket-modal"
          show
          on_cancel={JS.push("close_new_ticket_modal")}
        >
          <.header>New ticket</.header>

          <.simple_form
            for={@new_ticket_form}
            id="space-ticket-form"
            phx-change="validate_new_ticket"
            phx-submit="create_new_ticket"
          >
            <.input field={@new_ticket_form[:subject]} type="text" label="Summary" />
            <.input field={@new_ticket_form[:description]} type="textarea" label="Description" />

            <.input
              :if={@show_assignee?}
              field={@new_ticket_form[:assignee_id]}
              type="select"
              label="Assignee"
              prompt="Unassigned"
              options={@assignee_options}
            />

            <.input
              field={@new_ticket_form[:priority]}
              type="select"
              label="Priority"
              options={[Low: :low, Normal: :normal, High: :high, Urgent: :urgent]}
            />

            <:actions>
              <button type="button" phx-click="close_new_ticket_modal" class="btn btn-ghost">
                Cancel
              </button>
              <.button phx-disable-with="Creating...">Create ticket</.button>
            </:actions>
          </.simple_form>
        </.modal>
      <% else %>
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
              <.link
                :if={can?(@current_scope.user, :update_space, @space)}
                navigate={~p"/spaces/#{@space.key}/edit"}
                class="btn btn-ghost"
              >
                <.icon name="hero-pencil" class="size-4" /> Edit
              </.link>
              <button
                :if={can?(@current_scope.user, :delete_space, @space)}
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
      <% end %>
    </Layouts.app>
    """
  end

  attr :id, :string, required: true
  attr :column, :string, required: true
  attr :title, :string, required: true
  attr :count, :integer, required: true
  attr :list_id, :string, required: true
  attr :tickets_stream, :any, required: true
  attr :return_to, :string, required: true

  def kanban_column(assigns) do
    ~H"""
    <section
      id={@id}
      class="w-[320px] min-w-[320px] flex-shrink-0 rounded-2xl border border-base-300 bg-base-200/60 shadow-sm"
    >
      <header class="flex items-center justify-between px-3 py-2">
        <h2 class="text-[11px] font-bold uppercase tracking-wider text-base-content/50">{@title}</h2>
        <span class="text-xs font-mono text-base-content/50">{@count}</span>
      </header>

      <div class="px-2 pb-3">
        <div
          id={@list_id}
          phx-update="stream"
          data-kanban-dropzone
          data-kanban-column={@column}
          class="space-y-2 min-h-8"
        >
          <div
            id={"#{@list_id}-empty"}
            class="hidden only:block rounded-xl border border-dashed border-base-300 bg-base-100/60 p-3 text-sm text-base-content/50"
          >
            No tickets
          </div>

          <div
            :for={{id, ticket} <- @tickets_stream}
            id={id}
            draggable="true"
            data-ticket-id={ticket.id}
            data-kanban-column={@column}
          >
            <.ticket_card ticket={ticket} return_to={@return_to} />
          </div>
        </div>
      </div>
    </section>
    """
  end

  attr :ticket, :any, required: true
  attr :return_to, :string, required: true

  def ticket_card(assigns) do
    ~H"""
    <.link
      navigate={~p"/tickets/#{@ticket}?return_to=#{@return_to}"}
      class="group block rounded-xl border border-base-300 bg-base-100 p-3 shadow-sm transition hover:-translate-y-px hover:shadow-md"
    >
      <div class="flex items-start justify-between gap-3">
        <div class="min-w-0">
          <div class="flex items-center gap-2">
            <span class="font-mono text-xs text-base-content/50">#{@ticket.id}</span>
            <span class={["badge badge-sm", priority_badge_class(@ticket.priority)]}>
              {priority_label(@ticket.priority)}
            </span>
          </div>

          <div class="mt-2 font-medium leading-snug line-clamp-2 group-hover:underline">
            {@ticket.subject}
          </div>
        </div>

        <.icon
          name="hero-chevron-right"
          class="size-4 text-base-content/30 group-hover:text-base-content/60"
        />
      </div>
    </.link>
    """
  end

  defp template_label(:kanban), do: "Kanban"
  defp template_label(:service_desk), do: "Service Desk"
  defp template_label(:project), do: "Project"
  defp template_label(_), do: "Custom"

  defp new_ticket_form do
    %Support.Ticket{}
    |> Support.Ticket.create_changeset(%{})
    |> to_form()
  end

  defp assign_kanban(socket, space) do
    tickets = Support.list_tickets_by_space(space.id)

    todo = Enum.filter(tickets, &(&1.status in [:open]))
    doing = Enum.filter(tickets, &(&1.status in [:pending, :on_hold]))
    done = Enum.filter(tickets, &(&1.status in [:solved, :closed]))

    socket
    |> assign(:ticket_count, length(tickets))
    |> assign(:todo_count, length(todo))
    |> assign(:doing_count, length(doing))
    |> assign(:done_count, length(done))
    |> stream(:todo_tickets, todo, reset: true, dom_id: &"kanban-ticket-#{&1.id}")
    |> stream(:doing_tickets, doing, reset: true, dom_id: &"kanban-ticket-#{&1.id}")
    |> stream(:done_tickets, done, reset: true, dom_id: &"kanban-ticket-#{&1.id}")
  end

  defp priority_label(priority) when is_atom(priority) do
    priority
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp priority_badge_class(:low), do: "badge-ghost"
  defp priority_badge_class(:normal), do: "badge-info"
  defp priority_badge_class(:high), do: "badge-warning"
  defp priority_badge_class(:urgent), do: "badge-error"
  defp priority_badge_class(_), do: ""

  defp sanitize_new_ticket_params(socket, ticket_params) when is_map(ticket_params) do
    ticket_params = Map.put(ticket_params, "requester_id", socket.assigns.current_scope.user.id)

    if can?(socket.assigns.current_scope.user, :assign_ticket) do
      ticket_params
    else
      Map.drop(ticket_params, ["assignee_id"])
    end
  end
end
