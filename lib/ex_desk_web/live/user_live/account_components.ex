defmodule ExDeskWeb.UserLive.AccountComponents do
  use ExDeskWeb, :html

  @doc """
  Renders the sub-navigation for account-related pages.
  """
  attr :current_page, :atom, required: true

  def account_nav(assigns) do
    ~H"""
    <div class="flex items-center gap-4 border-b border-base-300 mb-8 overflow-x-auto pb-2">
      <.nav_tab
        label="Profile"
        icon="hero-user"
        href={~p"/users/profile"}
        active={@current_page == :profile}
        patch
      />
      <.nav_tab
        label="Account & Security"
        icon="hero-shield-check"
        href={~p"/users/settings"}
        active={@current_page == :settings}
      />
      <.nav_tab
        label="Preferences"
        icon="hero-adjustments-horizontal"
        href={~p"/users/preferences"}
        active={@current_page == :preferences}
        patch
      />
    </div>
    """
  end

  attr :label, :string, required: true
  attr :icon, :string, required: true
  attr :href, :string, required: true
  attr :active, :boolean, default: false
  attr :patch, :boolean, default: false

  defp nav_tab(assigns) do
    ~H"""
    <.link
      patch={@patch && @href}
      navigate={!@patch && @href}
      class={[
        "flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-lg transition-all whitespace-nowrap",
        @active && "bg-primary text-primary-content shadow-md",
        !@active && "text-base-content/60 hover:bg-base-200 hover:text-base-content"
      ]}
    >
      <.icon name={@icon} class="size-4" /> {@label}
    </.link>
    """
  end

  @doc """
  Renders a high-density user card preview.
  """
  attr :user_params, :map, default: %{}
  attr :current_user, :map, required: true

  def user_card_preview(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-xl border border-base-200 sticky top-8">
      <div class="card-body p-6">
        <div class="flex flex-col items-center text-center space-y-4">
          <div class="avatar">
            <div class="w-24 h-24 rounded-full ring ring-primary ring-offset-base-100 ring-offset-2 overflow-hidden bg-base-200">
              <img
                src={
                  Map.get(@user_params, "avatar_url") || @current_user.avatar_url ||
                    "https://api.dicebear.com/7.x/avataaars/svg?seed=#{@current_user.email}"
                }
                alt="Avatar Preview"
              />
            </div>
          </div>
          
          <div>
            <h2 class="text-xl font-bold text-base-content">
              {Map.get(@user_params, "name") || @current_user.name || "Anonymous User"}
            </h2>
            
            <p class="text-sm text-base-content/60 font-medium">
              {Map.get(@user_params, "job_title") || @current_user.job_title || "No Title"}
            </p>
          </div>
        </div>
        
        <div class="divider my-2"></div>
        
        <div class="space-y-3">
          <div class="flex items-center gap-3 text-sm">
            <.icon name="hero-building-office" class="size-4 text-base-content/40" />
            <span class="text-base-content/70">
              {Map.get(@user_params, "department") || @current_user.department || "No Department"}
            </span>
          </div>
          
          <div class="flex items-center gap-3 text-sm">
            <.icon name="hero-envelope" class="size-4 text-base-content/40" />
            <span class="text-base-content/70">{@current_user.email}</span>
          </div>
          
          <div class="flex items-center gap-3 text-sm">
            <.icon name="hero-phone" class="size-4 text-base-content/40" />
            <span class="text-base-content/70">
              {Map.get(@user_params, "phone") || @current_user.phone || "No Phone"}
            </span>
          </div>
        </div>
        
        <div class="mt-6 pt-4 border-t border-base-200">
          <div class="flex justify-between items-center text-[10px] uppercase tracking-wider text-base-content/40 font-bold">
            <span>Employee ID</span> <span>Locale</span>
          </div>
          
          <div class="flex justify-between items-center text-sm font-semibold mt-1">
            <span>
              {Map.get(@user_params, "employee_number") || @current_user.employee_number || "---"}
            </span>
            <span class="badge badge-sm badge-outline">
              {Map.get(@user_params, "locale") || @current_user.locale}
            </span>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
