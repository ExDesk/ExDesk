defmodule ExDeskWeb.UserLive.Account do
  use ExDeskWeb, :live_view

  alias ExDesk.Accounts
  import ExDeskWeb.UserLive.AccountComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="px-4 py-8 max-w-[1200px] mx-auto">
        <div class="mb-8">
          <.header>
            {header_title(@live_action)}
            <:subtitle>{header_subtitle(@live_action)}</:subtitle>
          </.header>
        </div>
         <.account_nav current_page={@live_action} />
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8 items-start">
          <div class="lg:col-span-2 space-y-6">
            <div class="card bg-base-100 shadow-xl border border-base-200">
              <div class="card-body p-6">
                <%= if @live_action == :profile do %>
                  <%= if map_size(@profile_form.source.changes) > 0 do %>
                    <div class="alert alert-warning mb-6">
                      <.icon name="hero-exclamation-triangle" class="size-5" />
                      <span>You have unsaved changes</span>
                    </div>
                  <% end %>
                  
                  <.form
                    for={@profile_form}
                    id="profile_form"
                    phx-submit="save_profile"
                    phx-change="validate_profile"
                    class="space-y-6"
                  >
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <.input
                        field={@profile_form[:name]}
                        type="text"
                        label="Full Name"
                        required
                        left_icon="hero-user"
                      />
                      <.input
                        field={@profile_form[:phone]}
                        type="text"
                        label="Phone Number"
                        left_icon="hero-phone"
                      />
                      <.input
                        field={@profile_form[:job_title]}
                        type="text"
                        label="Job Title"
                        left_icon="hero-briefcase"
                      />
                      <.input
                        field={@profile_form[:department]}
                        type="text"
                        label="Department"
                        left_icon="hero-building-office"
                      />
                      <.input
                        field={@profile_form[:employee_number]}
                        type="text"
                        label="Employee Number"
                        left_icon="hero-identification"
                      />
                      <div class="flex items-end gap-2">
                        <div class="flex-1">
                          <.input
                            field={@profile_form[:avatar_url]}
                            type="text"
                            label="Avatar URL"
                            left_icon="hero-photo"
                          />
                        </div>
                        
                        <button
                          type="button"
                          phx-click="preview_avatar"
                          class="btn btn-secondary mb-2"
                        >
                          Preview
                        </button>
                      </div>
                      
                      <%= if @avatar_preview_url do %>
                        <div class="mt-2 p-2 border rounded-lg bg-base-50">
                          <div class="text-xs font-bold text-base-content/50 uppercase mb-1">
                            Preview
                          </div>
                          
                          <img
                            src={@avatar_preview_url}
                            class="h-20 w-20 rounded-full object-cover border bg-base-200"
                            alt="Avatar Preview"
                          />
                        </div>
                      <% end %>
                    </div>
                    
                    <div class="space-y-2">
                      <div class="flex items-center justify-between">
                        <label class="label font-semibold py-0">Bio / Notes</label>
                        <span class="text-[10px] uppercase tracking-wider text-base-content/40 font-bold">
                          Markdown Supported
                        </span>
                      </div>
                      
                      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <.input
                          field={@profile_form[:notes]}
                          type="textarea"
                          class="textarea w-full min-h-[120px] font-mono text-sm"
                          placeholder="Tell us about yourself..."
                        />
                        <div class="hidden md:block border border-dashed border-base-300 rounded-lg p-3 bg-base-50 overflow-auto max-h-[160px]">
                          <div class="text-[10px] uppercase text-base-content/30 font-bold mb-2">
                            Live Preview
                          </div>
                          
                          <div class="prose prose-sm prose-slate max-w-none text-base-content/70">
                            {(@profile_form[:notes].value || "Nothing to preview yet...")
                            |> MDEx.to_html!(extension: [header_ids: ""])
                            |> raw()}
                          </div>
                        </div>
                      </div>
                    </div>
                    
                    <div class="card-actions justify-start pt-4 border-t border-base-200">
                      <.button
                        variant="primary"
                        class="w-full sm:w-auto"
                        disabled={@profile_form.source.changes == %{} || !@profile_form.source.valid?}
                      >
                        <span class="phx-submit-loading:hidden">Save Profile</span>
                        <span class="hidden phx-submit-loading:inline-flex items-center justify-center">
                          <span class="loading loading-spinner loading-xs mr-2"></span> Saving...
                        </span>
                      </.button>
                    </div>
                  </.form>
                <% end %>
                
                <%= if @live_action == :preferences do %>
                  <.form
                    for={@preferences_form}
                    id="preferences_form"
                    phx-submit="save_preferences"
                    phx-change="validate_preferences"
                    class="space-y-6"
                  >
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <.input
                        field={@preferences_form[:time_zone]}
                        type="select"
                        label="Time Zone"
                        left_icon="hero-clock"
                        options={[
                          {"UTC", "UTC"},
                          {"America/Sao_Paulo", "America/Sao_Paulo"},
                          {"Europe/London", "Europe/London"},
                          {"America/New_York", "America/New_York"}
                        ]}
                      />
                      <.input
                        field={@preferences_form[:locale]}
                        type="select"
                        label="Locale / Language"
                        left_icon="hero-language"
                        options={[
                          {"English", "en"},
                          {"Português (Brasil)", "pt-BR"},
                          {"Español", "es"}
                        ]}
                      />
                    </div>
                    
                    <div class="card-actions justify-start pt-4 border-t border-base-200">
                      <.button variant="primary" phx-disable-with="Saving...">
                        Save Preferences
                      </.button>
                    </div>
                  </.form>
                <% end %>
              </div>
            </div>
          </div>
          
          <div class="hidden lg:block lg:col-span-1">
            <.user_card_preview
              user_params={@user_params}
              current_user={@current_scope.user}
            />
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp header_title(:profile), do: "Profile Details"
  defp header_title(:preferences), do: "Preferences"

  defp header_subtitle(:profile), do: "Manage your public identity and contact information."

  defp header_subtitle(:preferences),
    do: "Customize your interface experience and regional settings."

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    {:ok,
     socket
     |> assign(:user_params, %{})
     |> assign(:avatar_preview_url, nil)
     |> assign_profile_form(user)
     |> assign_preferences_form(user)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("validate_profile", %{"user" => user_params}, socket) do
    form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_profile(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply,
     socket
     |> assign(profile_form: form)
     |> assign(user_params: user_params)}
  end

  def handle_event("save_profile", %{"user" => user_params}, socket) do
    case Accounts.update_user_profile(socket.assigns.current_scope.user, user_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Profile updated successfully.")
         |> assign(user_params: %{})
         |> assign(avatar_preview_url: nil)
         |> assign_profile_form(user)}

      {:error, changeset} ->
        {:noreply, assign(socket, profile_form: to_form(changeset))}
    end
  end

  def handle_event("preview_avatar", _params, socket) do
    # Try to get URL from validated params, or fallback to current user avatar if no params yet (optional, but checking params first)
    url = socket.assigns.user_params["avatar_url"] || socket.assigns.current_scope.user.avatar_url
    {:noreply, assign(socket, avatar_preview_url: url)}
  end

  @impl true
  def handle_event("validate_preferences", %{"user" => user_params}, socket) do
    form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_preferences(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply,
     socket
     |> assign(preferences_form: form)
     |> assign(user_params: user_params)}
  end

  def handle_event("save_preferences", %{"user" => user_params}, socket) do
    case Accounts.update_user_preferences(socket.assigns.current_scope.user, user_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Preferences updated successfully.")
         |> assign(user_params: %{})
         |> assign_preferences_form(user)}

      {:error, changeset} ->
        {:noreply, assign(socket, preferences_form: to_form(changeset))}
    end
  end

  defp assign_profile_form(socket, user) do
    assign(socket, profile_form: to_form(Accounts.change_user_profile(user)))
  end

  defp assign_preferences_form(socket, user) do
    assign(socket, preferences_form: to_form(Accounts.change_user_preferences(user)))
  end
end
