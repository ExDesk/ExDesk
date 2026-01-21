defmodule ExDeskWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use ExDeskWeb, :html

  alias ExDesk.Accounts
  alias ExDesk.Support

  embed_templates "layouts/*"

  @doc """
  Renders your app layout.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current scope containing user information"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="drawer lg:drawer-open font-sans antialiased">
      <input id="app-drawer" type="checkbox" class="drawer-toggle" />
      <div class="drawer-content flex flex-col min-h-screen bg-base-100">
        <!-- Mobile Header -->
        <header class="lg:hidden flex items-center justify-between border-b border-base-200 bg-base-100 px-4 py-3 sticky top-0 z-30">
          <div class="flex items-center gap-3">
            <label for="app-drawer" class="btn btn-square btn-ghost btn-sm drawer-button">
              <.icon name="hero-bars-3" class="size-6" />
            </label> <span class="font-bold text-lg tracking-tight">ExDesk</span>
          </div>
          
          <div :if={@current_scope} class="flex items-center gap-2">
            <.link navigate={~p"/users/profile"} class="avatar placeholder">
              <div class="bg-neutral text-neutral-content rounded-full w-8">
                <span class="text-xs">
                  {String.first(@current_scope.user.email) |> String.upcase()}
                </span>
              </div>
            </.link>
          </div>
        </header>
        
        <main class="flex-1 overflow-y-auto bg-base-100 p-4 lg:p-8">
          <div class="mx-auto max-w-7xl animate-pipeline-appear">{render_slot(@inner_block)}</div>
        </main>
      </div>
      
      <div class="drawer-side z-40">
        <label for="app-drawer" aria-label="close sidebar" class="drawer-overlay"></label>
        <.sidebar current_scope={@current_scope} />
      </div>
    </div>
     <.flash_group flash={@flash} />
    """
  end

  @doc """
  Renders the application sidebar with navigation.
  """
  attr :current_scope, :map, default: nil

  def sidebar(assigns) do
    ~H"""
    <aside class="flex flex-col w-72 min-h-full bg-base-100 border-r border-base-200 text-base-content">
      <!-- Sidebar Header -->
      <div class="h-16 flex items-center gap-3 px-6 border-b border-base-200">
        <.link navigate={~p"/dashboard"} class="flex items-center gap-2 group">
          <span class="font-black text-xl tracking-tight">
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
        <.sidebar_link
          icon="hero-ticket"
          label="Tickets"
          href={~p"/tickets"}
          badge={to_string(Support.count_total_tickets())}
        />
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
        <div class="text-xs font-semibold text-base-content/50 uppercase tracking-wider mt-6 mb-2 px-2">
          System
        </div>
         <.sidebar_link icon="hero-chart-bar" label="Reports" href={~p"/dashboard"} />
        <.sidebar_link icon="hero-cog-6-tooth" label="Settings" href={~p"/users/profile"} />
      </nav>
      <!-- User Footer -->
      <div :if={@current_scope} class="p-4 border-t border-base-200">
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

  @doc """
  Shows the flash group with standard titles and content.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} /> <.flash kind={:error} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("Connection lost")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect...")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
      
      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect...")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="relative flex items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />
      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
        title="System theme"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
        title="Light theme"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
        title="Dark theme"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
