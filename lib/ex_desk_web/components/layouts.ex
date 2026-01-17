defmodule ExDeskWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use ExDeskWeb, :html

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
    <div class="flex min-h-screen bg-base-200">
      <.sidebar current_scope={@current_scope} />
      <main class="flex-1 overflow-auto">{render_slot(@inner_block)}</main>
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
    <aside class="w-64 bg-base-100 border-r border-base-300 flex flex-col shadow-lg">
      <!-- Logo / Brand -->
      <div class="p-8 border-b border-base-300 flex flex-col items-center">
        <.link navigate={~p"/dashboard"} class="flex flex-col items-center gap-2 text-center group">
          <span class="text-4xl font-black tracking-tighter hover:scale-105 transition-transform duration-300">
            <span class="text-transparent bg-clip-text bg-gradient-to-r from-purple-500 to-indigo-600">Ex</span>Desk
          </span>
        </.link>
      </div>
      <!-- Navigation -->
      <nav class="flex-1 p-4 space-y-2">
        <.sidebar_link icon="hero-home" label="Dashboard" href={~p"/dashboard"} />
        <.sidebar_link icon="hero-ticket" label="Tickets" href={~p"/dashboard"} badge="8" />
        <.sidebar_link icon="hero-computer-desktop" label="Assets" href={~p"/dashboard"} />
        <.sidebar_link icon="hero-users" label="Users" href={~p"/dashboard"} />
        <.sidebar_link icon="hero-chart-bar" label="Reports" href={~p"/dashboard"} />
        <div class="divider my-4 text-xs text-base-content/50">Administration</div>
         <.sidebar_link icon="hero-user-circle" label="Account" href={~p"/users/profile"} />
      </nav>
      <!-- User Section -->
      <div :if={@current_scope} class="p-4 border-t border-base-300">
        <.link
          navigate={~p"/users/profile"}
          class="flex items-center gap-3 p-3 rounded-xl bg-base-200/50 hover:bg-base-200 transition-colors group"
        >
          <div class="avatar placeholder group-hover:scale-105 transition-transform">
            <div class="bg-gradient-to-br from-purple-500 to-indigo-600 text-white rounded-full w-10">
              <span class="text-sm font-bold">
                {String.first(@current_scope.user.email) |> String.upcase()}
              </span>
            </div>
          </div>
          
          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium text-base-content truncate">{@current_scope.user.email}</p>
            
            <.link
              href={~p"/users/log-out"}
              method="delete"
              class="text-xs text-base-content/60 hover:text-error transition-colors"
            >
              Sign out
            </.link>
          </div>
        </.link>
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
