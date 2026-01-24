defmodule ExDeskWeb.TicketLive.Show do
  use ExDeskWeb, :live_view

  alias ExDesk.Support

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} spaces={@spaces}>
      <div class="max-w-6xl mx-auto space-y-6">
        <div class="flex flex-col gap-4 md:flex-row md:items-start md:justify-between">
          <div class="min-w-0">
            <div class="flex items-center gap-2 mb-2">
              <.link navigate={back_href(@return_to, @ticket)} class="btn btn-ghost btn-sm">
                <.icon name="hero-arrow-left" class="size-4" /> {back_label(@return_to, @ticket)}
              </.link>
               <span class="badge badge-ghost badge-sm font-mono">#{@ticket.id}</span>
            </div>

            <h1 class="text-2xl md:text-3xl font-bold leading-tight truncate">{@ticket.subject}</h1>

            <div class="flex flex-wrap items-center gap-2 mt-3">
              <span class={[
                "badge badge-sm",
                status_badge_class(@ticket.status)
              ]}>
                {humanize_enum(@ticket.status)}
              </span>
              <span class={[
                "badge badge-sm",
                priority_badge_class(@ticket.priority)
              ]}>
                {humanize_enum(@ticket.priority)}
              </span>
              <span class="badge badge-ghost badge-sm">
                <.icon name="hero-chat-bubble-left-right" class="size-3" /> {humanize_enum(
                  @ticket.channel
                )}
              </span>
              <span :if={@ticket.due_at} class="badge badge-ghost badge-sm">
                <.icon name="hero-clock" class="size-3" /> Due {format_dt(@ticket.due_at)}
              </span>
            </div>
          </div>

          <div class="flex items-center gap-2 flex-shrink-0">
            <.link
              navigate={~p"/tickets/#{@ticket}/edit?return_to=#{back_href(@return_to, @ticket)}"}
              class="btn btn-ghost btn-sm"
            >
              <.icon name="hero-pencil" class="size-4" /> Edit
            </.link>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div class="lg:col-span-2 space-y-6">
            <section class="bg-base-100 rounded-box border border-base-300 p-5">
              <h2 class="text-sm font-semibold text-base-content/70 mb-3">Description</h2>

              <p :if={present?(@ticket.description)} class="whitespace-pre-wrap leading-relaxed">
                {@ticket.description}
              </p>

              <p :if={!present?(@ticket.description)} class="text-base-content/60 italic">
                No description provided.
              </p>
            </section>

            <section class="bg-base-100 rounded-box border border-base-300 p-5">
              <div class="flex items-center justify-between gap-4 mb-3">
                <h2 class="text-sm font-semibold text-base-content/70">Conversation</h2>

                <span class="text-xs text-base-content/50">
                  {length(@ticket.comments)} comment(s)
                </span>
              </div>

              <div :if={@ticket.comments == []} class="text-base-content/60 italic">
                No comments yet.
              </div>

              <div
                :for={comment <- sorted_comments(@ticket.comments)}
                class="py-4 first:pt-0 last:pb-0"
              >
                <div class="flex items-start gap-3">
                  <div class="mt-1 size-8 rounded-full bg-base-200 flex items-center justify-center flex-shrink-0">
                    <.icon name="hero-user" class="size-4 text-base-content/50" />
                  </div>

                  <div class="min-w-0 flex-1">
                    <div class="flex flex-wrap items-center gap-x-2 gap-y-1">
                      <span class="font-semibold truncate">{user_label(comment.author)}</span>
                      <span class="text-xs text-base-content/50">
                        {format_dt(comment.inserted_at)}
                      </span>
                      <span class={[
                        "badge badge-xs",
                        if(comment.is_public, do: "badge-ghost", else: "badge-neutral")
                      ]}>
                        {if(comment.is_public, do: "public", else: "internal")}
                      </span>
                    </div>

                    <div class="mt-2 whitespace-pre-wrap leading-relaxed">{comment.body}</div>
                  </div>
                </div>
              </div>
            </section>
          </div>

          <aside class="space-y-6">
            <section class="bg-base-100 rounded-box border border-base-300 p-5">
              <h2 class="text-sm font-semibold text-base-content/70 mb-3">Details</h2>

              <.list>
                <:item title="Requester">{user_label(@ticket.requester)}</:item>

                <:item title="Assignee">{user_label(@ticket.assignee)}</:item>

                <:item title="Group">{group_label(@ticket.group)}</:item>

                <:item title="Created">{format_dt(@ticket.inserted_at)}</:item>

                <:item title="Updated">{format_dt(@ticket.updated_at)}</:item>

                <:item :if={@ticket.tags != []} title="Tags">
                  <div class="flex flex-wrap gap-1.5">
                    <span :for={tag <- @ticket.tags} class="badge badge-ghost badge-sm">{tag}</span>
                  </div>
                </:item>
              </.list>
            </section>

            <section class="bg-base-100 rounded-box border border-base-300 p-5">
              <h2 class="text-sm font-semibold text-base-content/70 mb-3">Activity</h2>

              <div :if={@ticket.activities == []} class="text-base-content/60 italic">
                No activity yet.
              </div>

              <div
                :for={activity <- sorted_activities(@ticket.activities)}
                class="py-3 first:pt-0 last:pb-0"
              >
                <div class="text-sm">
                  <span class="font-semibold">{user_label(activity.actor)}</span>
                  <span class="text-base-content/60">{activity_text(activity)}</span>
                </div>

                <div class="text-xs text-base-content/50 mt-1">{format_dt(activity.inserted_at)}</div>
              </div>
            </section>
          </aside>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id} = params, _session, socket) do
    ticket = Support.fetch_ticket!(id)
    return_to = safe_return_to(Map.get(params, "return_to"))

    {:ok,
     socket
     |> assign(:page_title, ticket.subject)
     |> assign(:return_to, return_to)
     |> assign(:ticket, ticket)}
  end

  defp safe_return_to(nil), do: nil

  defp safe_return_to(val) when is_binary(val) do
    val = String.trim(val)

    cond do
      val == "" -> nil
      String.starts_with?(val, "//") -> nil
      String.starts_with?(val, "/") -> val
      true -> nil
    end
  end

  defp back_href(return_to, _ticket) when is_binary(return_to), do: return_to
  defp back_href(nil, %{space: %{key: key}}), do: ~p"/spaces/#{key}"
  defp back_href(nil, _ticket), do: ~p"/tickets"

  defp back_label(return_to, ticket) when is_binary(return_to) do
    cond do
      return_to == "/tickets" ->
        "Tickets"

      String.starts_with?(return_to, "/spaces/") and match?(%{space: %{name: _}}, ticket) ->
        ticket.space.name

      String.starts_with?(return_to, "/spaces/") ->
        "Space"

      true ->
        "Back"
    end
  end

  defp back_label(nil, %{space: %{name: name}}), do: name
  defp back_label(nil, _ticket), do: "Tickets"

  defp status_badge_class(:open), do: "badge-warning"
  defp status_badge_class(:pending), do: "badge-info"
  defp status_badge_class(:on_hold), do: "badge-ghost"
  defp status_badge_class(:solved), do: "badge-success"
  defp status_badge_class(:closed), do: "badge-neutral"
  defp status_badge_class(_), do: ""

  defp priority_badge_class(:low), do: "badge-ghost"
  defp priority_badge_class(:normal), do: "badge-info"
  defp priority_badge_class(:high), do: "badge-warning"
  defp priority_badge_class(:urgent), do: "badge-error"
  defp priority_badge_class(_), do: ""

  defp humanize_enum(nil), do: "-"

  defp humanize_enum(val) when is_atom(val) do
    val
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp present?(val) when is_binary(val), do: String.trim(val) != ""
  defp present?(_), do: false

  defp format_dt(nil), do: "-"

  defp format_dt(%DateTime{} = dt) do
    Calendar.strftime(dt, "%d/%m/%Y %H:%M")
  end

  defp user_label(nil), do: "Unassigned"
  defp user_label(%{email: email}) when is_binary(email), do: email
  defp user_label(_), do: "Unknown"

  defp group_label(nil), do: "-"
  defp group_label(%{name: name}) when is_binary(name), do: name
  defp group_label(_), do: "-"

  defp sorted_comments(comments) when is_list(comments) do
    Enum.sort_by(comments, &(&1.inserted_at || ~U[0000-01-01 00:00:00Z]), DateTime)
  end

  defp sorted_activities(activities) when is_list(activities) do
    activities
    |> Enum.sort_by(&(&1.inserted_at || ~U[0000-01-01 00:00:00Z]), DateTime)
    |> Enum.reverse()
    |> Enum.take(12)
  end

  defp activity_text(%{action: :created}), do: "created the ticket"
  defp activity_text(%{action: :commented}), do: "added a comment"
  defp activity_text(%{action: :status_changed}), do: "changed status"
  defp activity_text(%{action: :priority_changed}), do: "changed priority"
  defp activity_text(%{action: :assigned}), do: "assigned the ticket"
  defp activity_text(%{action: :unassigned}), do: "unassigned the ticket"
  defp activity_text(%{action: :group_changed}), do: "changed group"
  defp activity_text(_), do: "updated the ticket"
end
