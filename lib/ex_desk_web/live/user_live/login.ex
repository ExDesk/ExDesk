defmodule ExDeskWeb.UserLive.Login do
  use ExDeskWeb, :live_view

  alias ExDesk.Accounts

  @doc """
  Renders the Authentication Interface.

  Presents the visual identity surface for users to claim their identity, supporting both
  traditional credential-based verification and passwordless magic link initiation.
  """
  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen w-full">
      <!-- Left Side (Branding) -->
      <div class="hidden lg:flex w-1/2 bg-zinc-900 relative flex-col items-center justify-center p-12 text-white overflow-hidden">
        <div class="absolute inset-0 bg-gradient-to-br from-purple-900/30 to-blue-900/10 pointer-events-none">
        </div>
        <!-- Background Pattern -->
        <div class="absolute inset-0 z-0 opacity-10 pointer-events-none select-none">
          <img
            src={~p"/images/login-bg.png"}
            class="w-full h-full object-cover mix-blend-overlay"
            alt=""
          />
        </div>
        
        <div class="relative z-10 flex flex-col items-center max-w-lg text-center">
          <h1 class="text-6xl font-black tracking-tighter mb-4 text-white drop-shadow-lg">
            <span class="text-transparent bg-clip-text bg-gradient-to-r from-purple-400 to-purple-200">Ex</span>Desk
          </h1>
          
          <div class="font-mono text-lg sm:text-xl text-zinc-300 bg-zinc-800/50 px-6 py-4 rounded-xl border border-zinc-700/50 backdrop-blur-sm shadow-2xl mt-4">
            <span class="text-purple-400 animate-pipeline-appear" style="animation-delay: 100ms">
              IT_Issues
            </span>
            <span class="text-zinc-500 mx-2 animate-pipeline-appear" style="animation-delay: 300ms">
              |&gt;
            </span>
            <span class="text-white font-bold animate-pipeline-appear" style="animation-delay: 500ms">
              ExDesk
            </span>
            <span class="text-zinc-500 mx-2 animate-pipeline-appear" style="animation-delay: 700ms">
              |&gt;
            </span>
            <span class="text-green-400 animate-pipeline-appear" style="animation-delay: 900ms">
              Solved
            </span>
          </div>
        </div>
        <!-- Decoration -->
        <div class="absolute bottom-0 left-0 w-full h-1/3 bg-gradient-to-t from-zinc-900/80 to-transparent">
        </div>
      </div>
      <!-- Right Side (Login Form) -->
      <div class="w-full lg:w-1/2 flex flex-col justify-center px-8 py-12 sm:px-12 lg:px-24 bg-white dark:bg-base-100 relative">
        <div class="mx-auto w-full max-w-md">
          <!-- Logo for Mobile/Form Context -->
          <div class="text-center mb-12">
            <h2 class="text-3xl font-bold text-base-content tracking-tight">Welcome back</h2>
            
            <div class="mt-3 text-base text-base-content/70">
              <%= if @current_scope do %>
                Please reauthenticate to continue.
              <% else %>
                Don't have an account? Contact your administrator.
              <% end %>
            </div>
          </div>
          
          <div :if={local_mail_adapter?()} class="alert alert-info mb-8 shadow-sm">
            <.icon name="hero-information-circle" class="size-6 shrink-0" />
            <div>
              <p class="font-bold">Local Mail Adapter</p>
              
              <p class="text-sm">
                Visit <.link href="/dev/mailbox" class="underline">mailbox</.link> to see emails.
              </p>
            </div>
          </div>
          
          <div class="space-y-8">
            <.form
              :let={f}
              for={@form}
              id="login_form"
              action={~p"/users/log-in"}
              phx-submit="submit"
              phx-trigger-action={@trigger_submit}
              class="space-y-6"
            >
              <.input
                readonly={!!@current_scope}
                field={f[:email]}
                type="email"
                label="Email address"
                autocomplete="email"
                required
                phx-mounted={JS.focus()}
                class="input input-bordered input-lg w-full focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/50 rounded-xl bg-gray-50 dark:bg-zinc-900/50"
              />
              <.input
                field={@form[:password]}
                type="password"
                label="Password"
                autocomplete="current-password"
                class="input input-bordered input-lg w-full focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/50 rounded-xl bg-gray-50 dark:bg-zinc-900/50"
              />
              <div class="flex items-center justify-between">
                <div class="flex items-center">
                  <input
                    id="remember_me"
                    name={@form[:remember_me].name}
                    type="checkbox"
                    value="true"
                    class="checkbox checkbox-primary rounded-md focus:ring-2 focus:ring-primary/50"
                  />
                  <label
                    for="remember_me"
                    class="ml-3 block text-sm font-medium text-base-content/80"
                  >
                    Remember me
                  </label>
                </div>
              </div>
              
              <div class="pt-2 space-y-4">
                <button
                  type="submit"
                  name="action"
                  value="password"
                  phx-disable-with="Authenticating..."
                  class="btn btn-primary btn-lg w-full rounded-xl shadow-lg shadow-primary/20 hover:scale-[1.01] transition-transform"
                >
                  Sign in <span aria-hidden="true">→</span>
                </button>
                <div class="relative py-2">
                  <div class="absolute inset-0 flex items-center">
                    <div class="w-full border-t border-base-300"></div>
                  </div>
                  
                  <div class="relative flex justify-center text-sm">
                    <span class="px-2 bg-white dark:bg-base-100 text-base-content/50 text-xs">
                      or
                    </span>
                  </div>
                </div>
                
                <button
                  type="submit"
                  name="action"
                  value="magic"
                  phx-disable-with="Sending..."
                  class="btn btn-ghost btn-outline btn-lg w-full rounded-xl hover:bg-base-200 transition-colors font-normal"
                >
                  Send Magic Link
                </button>
              </div>
            </.form>
          </div>
        </div>
        
        <div class="absolute bottom-6 left-0 w-full text-center">
          <p class="text-xs text-base-content/40 font-medium">
            © 2026 ExDesk Inc. • Privacy Policy • Terms of Service • Help Center
          </p>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Initializes the Authentication Context.

  Establishes the session boundaries and prepares the identity verification form,
  potentially hydrating the context with pre-filled identity attributes (e.g., email)
  from the cross-boundary flash scope.
  """
  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @doc """
  Processes an Identity Verification Request.

  Acts as the domain gateway for authentication commands:
  - **Password**: Validates the provided credentials against the Identity Store.
  - **Magic Link**: Issues a secure, time-bounded access token delivered via the Email Notification Service.
  """
  @impl true
  def handle_event("submit", %{"action" => "password"}, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit", params, socket) when not is_map_key(params, "action") do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit", %{"action" => "magic", "user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:ex_desk, ExDesk.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
