defmodule ExDeskWeb.Sidebar do
  use ExDeskWeb, :html

  import ExDeskWeb.Authorization, only: [can?: 2]

  alias ExDesk.Accounts

  @doc """
  Renders the application sidebar with navigation.
  """
  attr :current_scope, :map, default: nil
  attr :spaces, :list, default: []

  def sidebar(assigns) do
    ~H"""
    <aside class="flex flex-col w-72 min-h-full bg-base-100 border-r border-base-300 text-base-content">
      <!-- Sidebar Header -->
      <div class="h-16 flex items-center justify-center border-b border-base-300">
        <.link navigate={~p"/dashboard"} class="flex items-center gap-2 group">
          <span class="font-black text-4xl tracking-tight">
            <span class="text-transparent bg-clip-text bg-gradient-to-r from-purple-600 to-purple-400 dark:from-purple-400 dark:to-purple-200">Ex</span>Desk
          </span>
        </.link>
      </div>
      <!-- Navigation -->
      <nav class="flex-1 overflow-y-auto p-4 space-y-1">
        <div class="text-xs font-semibold text-base-content/50 uppercase tracking-wider mb-2 px-2">
          Overview
        </div>
        <.sidebar_link icon="hero-home" label="Dashboard" href={~p"/dashboard"} />
        <div class="text-xs font-semibold text-base-content/50 uppercase tracking-wider mt-6 mb-2 px-2">
          Spaces
        </div>
        <.space_link :for={space <- @spaces} space={space} />
        <.link
          navigate={~p"/spaces/new"}
          class="flex items-center gap-3 px-4 py-2 rounded-xl text-base-content/50 hover:bg-base-200 hover:text-base-content transition-all group"
        >
          <.icon name="hero-plus" class="size-4" /> <span class="text-sm">Create Space</span>
        </.link>
        <div class="text-xs font-semibold text-base-content/50 uppercase tracking-wider mt-6 mb-2 px-2">
          Manage
        </div>
        <.sidebar_link icon="hero-computer-desktop" label="Assets" href={~p"/dashboard"} />
        <.sidebar_link
          icon="hero-users"
          label="Users"
          href={~p"/dashboard"}
          badge={to_string(Accounts.count_users())}
        />
        <.sidebar_link
          :if={@current_scope && can?(@current_scope.user, :list_groups)}
          icon="hero-user-group"
          label="Groups"
          href={~p"/groups"}
        />
        <div class="text-xs font-semibold text-base-content/50 uppercase tracking-wider mt-6 mb-2 px-2">
          System
        </div>
        <.sidebar_link icon="hero-chart-bar" label="Reports" href={~p"/dashboard"} />
        <.sidebar_link icon="hero-cog-6-tooth" label="Settings" href={~p"/users/profile"} />
      </nav>
      <!-- User Footer -->
      <div :if={@current_scope} class="p-4 border-t border-base-300">
        <div class="flex items-center gap-3 p-3 rounded-xl bg-base-200/50 hover:bg-base-200 transition-colors">
          <div class={["avatar", !@current_scope.user.avatar_url && "placeholder"]}>
            <div class={[
              "bg-neutral text-neutral-content rounded-full w-9",
              @current_scope.user.avatar_url && "ring ring-primary ring-offset-base-100 ring-offset-1"
            ]}>
              <span :if={!@current_scope.user.avatar_url} class="text-sm font-semibold">
                {String.first(@current_scope.user.email) |> String.upcase()}
              </span>
              <img :if={@current_scope.user.avatar_url} src={@current_scope.user.avatar_url} />
            </div>
          </div>

          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium truncate">{@current_scope.user.email}</p>

            <.link
              href={~p"/users/log-out"}
              method="delete"
              class="text-xs text-error hover:underline"
            >
              Sign out
            </.link>
          </div>
        </div>
      </div>
    </aside>
    """
  end

  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :href, :string, required: true
  attr :badge, :string, default: nil

  defp sidebar_link(assigns) do
    ~H"""
    <.link
      navigate={@href}
      class="flex items-center gap-3 px-4 py-3 rounded-xl text-base-content/70 hover:bg-base-200 hover:text-base-content transition-all group"
    >
      <.icon name={@icon} class="size-5 group-hover:scale-110 transition-transform" />
      <span class="flex-1 font-medium">{@label}</span>
      <span :if={@badge} class="badge badge-primary badge-sm">{@badge}</span>
    </.link>
    """
  end

  attr :space, :map, required: true

  defp space_link(assigns) do
    ~H"""
    <.link
      navigate={~p"/spaces/#{@space.key}"}
      class="flex items-center gap-3 px-4 py-2.5 rounded-xl text-base-content/70 hover:bg-base-200 hover:text-base-content transition-all group"
    >
      <div
        class="size-5 rounded flex-shrink-0"
        style={"background-color: #{@space.color}"}
      /> <span class="flex-1 font-medium truncate">{@space.name}</span>
    </.link>
    """
  end
end
