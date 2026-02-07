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
    can_move_kanban? = can?(socket.assigns.current_scope.user, :transition_ticket)

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
      |> assign(:can_move_kanban?, can_move_kanban?)
      |> assign(:assignee_options, assignee_options)
      |> assign(:kanban_filters, %{})
      |> assign(:kanban_filters_form, kanban_filters_form(show_assignee?, %{}))

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    space = socket.assigns.space

    socket =
      if space.template == :kanban do
        filters = parse_kanban_filters(params, socket.assigns.show_assignee?)

        socket
        |> assign(:kanban_filters, filters)
        |> assign(
          :kanban_filters_form,
          kanban_filters_form(socket.assigns.show_assignee?, filters)
        )
        |> assign_kanban(space, filters)
      else
        socket
      end

    {:noreply, socket}
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
            assign_kanban(socket, space, socket.assigns.kanban_filters)
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

    if !socket.assigns.can_move_kanban? do
      {:noreply,
       socket
       |> put_flash(:error, "You are not authorized to move tickets.")
       |> assign_kanban(space, socket.assigns.kanban_filters)}
    else
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
          {:noreply, assign_kanban(socket, space, socket.assigns.kanban_filters)}

        {:error, reason} ->
          {:noreply,
           socket
           |> put_flash(:error, "Could not move ticket: #{inspect(reason)}")
           |> assign_kanban(space, socket.assigns.kanban_filters)}
      end
    end
  end

  @impl true
  def handle_event("kanban_filter_change", %{"kanban_filters" => raw_filters}, socket) do
    filters = parse_kanban_filters(raw_filters, socket.assigns.show_assignee?)
    space_key = socket.assigns.space.key

    params =
      filters
      |> Map.take([:q, :priority, :assignee_id])
      |> Enum.reduce(%{}, fn
        {:assignee_id, :unassigned}, acc ->
          Map.put(acc, :assignee_id, "unassigned")

        {:assignee_id, val}, acc when is_integer(val) ->
          Map.put(acc, :assignee_id, to_string(val))

        {_key, nil}, acc ->
          acc

        {_key, ""}, acc ->
          acc

        {key, val}, acc ->
          Map.put(acc, key, val)
      end)

    {:noreply, push_patch(socket, to: ~p"/spaces/#{space_key}?#{params}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} spaces={@spaces}>
      <%= if @space.template == :kanban do %>
        <div id="kanban-shell" class="mx-auto max-w-7xl space-y-5">
          <div class="flex items-start justify-between gap-4">
            <div class="flex items-center gap-4 min-w-0">
              <div
                class="size-14 rounded-xl flex items-center justify-center flex-shrink-0 shadow-sm"
                style={"background-color: #{@space.color}"}
              >
                <.icon name="hero-rectangle-stack" class="size-7 text-white" />
              </div>

              <div class="min-w-0">
                <div class="flex flex-wrap items-center gap-x-2 gap-y-1">
                  <span class="text-xs font-mono text-base-content/50">Spaces</span>
                  <.icon name="hero-chevron-right" class="size-3 text-base-content/30" />
                  <span class="text-xs font-mono text-base-content/50">{@space.key}</span>
                  <span class="text-xs text-base-content/40">Board</span>
                </div>

                <h1 class="text-2xl md:text-3xl font-bold truncate">{@space.name}</h1>
                <p class="text-base-content/60">Kanban · {@ticket_count} issues</p>
              </div>
            </div>

            <div class="flex items-center gap-2 flex-shrink-0">
              <button
                id="space-new-ticket"
                phx-click="open_new_ticket_modal"
                class="btn btn-primary btn-sm"
              >
                <.icon name="hero-plus" class="size-4" /> Create
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

          <div class="kanban-controls flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
            <.form
              for={@kanban_filters_form}
              id="kanban-filter-form"
              phx-change="kanban_filter_change"
              class="flex flex-col gap-3 md:flex-row md:items-end"
            >
              <div class="w-full md:w-96">
                <.input
                  field={@kanban_filters_form[:q]}
                  id="kanban-search"
                  type="search"
                  placeholder="Search issues"
                  left_icon="hero-magnifying-glass"
                  phx-debounce="250"
                  class="w-full input input-sm"
                />
              </div>

              <div class="w-full md:w-52">
                <.input
                  field={@kanban_filters_form[:priority]}
                  id="kanban-filter-priority"
                  type="select"
                  prompt="All priorities"
                  options={[Low: "low", Normal: "normal", High: "high", Urgent: "urgent"]}
                  class="w-full select select-sm"
                />
              </div>

              <div :if={@show_assignee?} class="w-full md:w-64">
                <.input
                  field={@kanban_filters_form[:assignee_id]}
                  id="kanban-filter-assignee"
                  type="select"
                  prompt="All assignees"
                  options={assignee_filter_options(@assignee_options)}
                  class="w-full select select-sm"
                />
              </div>

              <.link patch={~p"/spaces/#{@space.key}"} class="btn btn-ghost btn-sm">Clear</.link>
            </.form>

            <div class="flex items-center gap-3 justify-end text-xs text-base-content/50">
              <%= if @can_move_kanban? do %>
                <span class="inline-flex items-center gap-1">
                  <.icon name="hero-arrows-up-down" class="size-3" /> Drag to reorder
                </span>
              <% else %>
                <span class="inline-flex items-center gap-1">
                  <.icon name="hero-lock-closed" class="size-3" /> Read-only
                </span>
              <% end %>
            </div>
          </div>

          <div
            id="kanban-board"
            phx-hook={@can_move_kanban? && "KanbanDnD"}
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
              space_key={@space.key}
              draggable?={@can_move_kanban?}
            />

            <.kanban_column
              id="kanban-col-doing"
              column="doing"
              title="In progress"
              count={@doing_count}
              list_id="kanban-doing-tickets"
              tickets_stream={@streams.doing_tickets}
              return_to={~p"/spaces/#{@space.key}"}
              space_key={@space.key}
              draggable?={@can_move_kanban?}
            />

            <.kanban_column
              id="kanban-col-done"
              column="done"
              title="Done"
              count={@done_count}
              list_id="kanban-done-tickets"
              tickets_stream={@streams.done_tickets}
              return_to={~p"/spaces/#{@space.key}"}
              space_key={@space.key}
              draggable?={@can_move_kanban?}
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
  attr :space_key, :string, required: true
  attr :draggable?, :boolean, default: true

  def kanban_column(assigns) do
    ~H"""
    <section
      id={@id}
      class="w-[320px] min-w-[320px] flex-shrink-0 rounded-2xl border border-base-300 bg-base-200/60 shadow-sm"
    >
      <header class="sticky top-0 z-10 flex items-center justify-between px-3 py-2 bg-base-200/80 backdrop-blur border-b border-base-300">
        <div class="flex items-center gap-2 min-w-0">
          <span class={["size-2 rounded-full", kanban_column_dot_class(@column)]} />
          <h2 class="text-[11px] font-bold uppercase tracking-wider text-base-content/60 truncate">
            {@title}
          </h2>
          <span class="badge badge-ghost badge-sm font-mono">{@count}</span>
        </div>

        <button type="button" class="btn btn-ghost btn-xs" aria-label="Column actions">
          <.icon name="hero-ellipsis-horizontal" class="size-4" />
        </button>
      </header>

      <div class="px-2 pb-3 pt-2">
        <div
          id={@list_id}
          phx-update="stream"
          data-kanban-dropzone
          data-kanban-column={@column}
          class="mt-2 space-y-2 min-h-8 rounded-xl p-2 bg-base-200/40"
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
            draggable={if(@draggable?, do: "true", else: "false")}
            data-ticket-id={ticket.id}
            data-kanban-column={@column}
          >
            <.ticket_card ticket={ticket} return_to={@return_to} space_key={@space_key} />
          </div>
        </div>
      </div>
    </section>
    """
  end

  attr :ticket, :any, required: true
  attr :return_to, :string, required: true
  attr :space_key, :string, required: true

  def ticket_card(assigns) do
    ~H"""
    <.link
      navigate={~p"/tickets/#{@ticket}?return_to=#{@return_to}"}
      class="group block rounded-xl border border-base-300 bg-base-100 px-3 py-2 shadow-sm transition hover:-translate-y-px hover:shadow-md"
    >
      <div class="flex items-start justify-between gap-3">
        <div class="min-w-0">
          <div class="flex items-center gap-2">
            <span class="font-mono text-[11px] text-base-content/60">
              {ticket_key(@space_key, @ticket)}
            </span>

            <span class={[
              "inline-flex items-center gap-1 text-[11px]",
              priority_icon_class(@ticket.priority)
            ]}>
              <.icon name={priority_icon_name(@ticket.priority)} class="size-3" />
              {priority_label(@ticket.priority)}
            </span>
          </div>

          <div class="mt-1 text-sm font-semibold leading-snug line-clamp-2 group-hover:underline">
            {@ticket.subject}
          </div>
        </div>

        <.icon
          name="hero-chevron-right"
          class="size-4 text-base-content/30 group-hover:text-base-content/60"
        />
      </div>

      <div class="mt-2 flex items-center justify-between gap-2">
        <div class="flex flex-wrap items-center gap-1.5 min-w-0">
          <span :for={tag <- Enum.take(@ticket.tags, 2)} class="badge badge-ghost badge-xs truncate">
            {tag}
          </span>

          <span :if={length(@ticket.tags) > 2} class="text-[11px] text-base-content/50">
            +{length(@ticket.tags) - 2}
          </span>

          <span
            :if={@ticket.due_at}
            class="inline-flex items-center gap-1 text-[11px] text-base-content/50"
          >
            <.icon name="hero-clock" class="size-3" /> Due {format_due(@ticket.due_at)}
          </span>
        </div>

        <div
          class="tooltip tooltip-left"
          data-tip={assignee_tooltip(@ticket)}
        >
          <div class="size-6 rounded-full bg-base-200 border border-base-300 flex items-center justify-center text-[11px] font-mono text-base-content/60">
            {assignee_initials(@ticket)}
          </div>
        </div>
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

  defp assign_kanban(socket, space, filters) do
    tickets = Support.list_tickets_by_space(space.id, filters)

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

  defp kanban_filters_form(show_assignee?, filters) when is_map(filters) do
    base = %{
      "q" => Map.get(filters, :q, ""),
      "priority" => Map.get(filters, :priority, "")
    }

    params =
      if show_assignee? do
        assignee_id =
          case Map.get(filters, :assignee_id) do
            :unassigned -> "unassigned"
            id when is_integer(id) -> to_string(id)
            _ -> ""
          end

        Map.put(base, "assignee_id", assignee_id)
      else
        base
      end

    to_form(params, as: :kanban_filters)
  end

  defp assignee_filter_options(assignee_options) when is_list(assignee_options) do
    [
      {"Unassigned", "unassigned"}
      | Enum.map(assignee_options, fn {email, id} -> {email, to_string(id)} end)
    ]
  end

  defp kanban_column_dot_class("todo"), do: "bg-warning"
  defp kanban_column_dot_class("doing"), do: "bg-info"
  defp kanban_column_dot_class("done"), do: "bg-success"
  defp kanban_column_dot_class(_), do: "bg-base-content/30"

  defp ticket_key(space_key, %{id: id}) when is_binary(space_key) and is_integer(id),
    do: "#{space_key}-#{id}"

  defp ticket_key(_space_key, %{id: id}) when is_integer(id), do: "##{id}"

  defp parse_kanban_filters(params, show_assignee?) when is_map(params) do
    q = params |> Map.get("q", "") |> to_string() |> String.trim()
    priority = params |> Map.get("priority", "") |> to_string() |> String.trim()

    base =
      %{}
      |> maybe_put_filter(:q, q)
      |> maybe_put_filter(:priority, priority)

    if show_assignee? do
      assignee_id = params |> Map.get("assignee_id", "") |> to_string() |> String.trim()

      case assignee_id do
        "" ->
          base

        "unassigned" ->
          Map.put(base, :assignee_id, :unassigned)

        val ->
          case Integer.parse(val) do
            {id, ""} -> Map.put(base, :assignee_id, id)
            _ -> base
          end
      end
    else
      base
    end
  end

  defp maybe_put_filter(filters, _key, ""), do: filters
  defp maybe_put_filter(filters, _key, nil), do: filters
  defp maybe_put_filter(filters, key, val), do: Map.put(filters, key, val)

  defp priority_icon_name(:low), do: "hero-arrow-down"
  defp priority_icon_name(:normal), do: "hero-minus"
  defp priority_icon_name(:high), do: "hero-arrow-up"
  defp priority_icon_name(:urgent), do: "hero-exclamation-triangle"
  defp priority_icon_name(_), do: "hero-minus"

  defp priority_icon_class(:low), do: "text-base-content/50"
  defp priority_icon_class(:normal), do: "text-info"
  defp priority_icon_class(:high), do: "text-warning"
  defp priority_icon_class(:urgent), do: "text-error"
  defp priority_icon_class(_), do: "text-base-content/50"

  defp format_due(%DateTime{} = dt), do: Calendar.strftime(dt, "%b %d")
  defp format_due(_), do: "-"

  defp assignee_initials(%{assignee: %{email: email}}) when is_binary(email), do: initials(email)
  defp assignee_initials(%{assignee_id: nil}), do: "--"
  defp assignee_initials(_), do: "?"

  defp assignee_tooltip(%{assignee: %{email: email}}) when is_binary(email), do: email
  defp assignee_tooltip(%{assignee_id: nil}), do: "Unassigned"
  defp assignee_tooltip(_), do: "Unknown"

  defp initials(email) when is_binary(email) do
    base = email |> String.split("@") |> List.first() |> to_string() |> String.trim()

    case String.length(base) do
      0 -> "?"
      1 -> String.upcase(base)
      _ -> base |> String.slice(0, 2) |> String.upcase()
    end
  end

  defp sanitize_new_ticket_params(socket, ticket_params) when is_map(ticket_params) do
    ticket_params = Map.put(ticket_params, "requester_id", socket.assigns.current_scope.user.id)

    if can?(socket.assigns.current_scope.user, :assign_ticket) do
      ticket_params
    else
      Map.drop(ticket_params, ["assignee_id"])
    end
  end
end
