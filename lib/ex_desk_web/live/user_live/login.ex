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
        <!-- Gradient overlay -->
        <div class="absolute inset-0 bg-gradient-to-br from-purple-900/30 to-blue-900/10 pointer-events-none">
        </div>
        <!-- Grain/Noise texture overlay -->
        <div
          class="absolute inset-0 opacity-[0.15] pointer-events-none"
          style="background-image: url('data:image/svg+xml,%3Csvg viewBox=%270 0 256 256%27 xmlns=%27http://www.w3.org/2000/svg%27%3E%3Cfilter id=%27noise%27%3E%3CfeTurbulence type=%27fractalNoise%27 baseFrequency=%270.8%27 numOctaves=%274%27 stitchTiles=%27stitch%27/%3E%3C/filter%3E%3Crect width=%27100%25%27 height=%27100%25%27 filter=%27url(%23noise)%27/%3E%3C/svg%3E');"
        >
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
          <h1 class="text-6xl font-black tracking-tighter mb-2 text-white drop-shadow-lg">
            <span class="text-transparent bg-clip-text bg-gradient-to-r from-purple-400 to-purple-200">Ex</span>Desk
          </h1>

          <p class="text-zinc-400 text-sm font-medium tracking-wide mb-8">
            IT Service Management, Simplified
          </p>
          <!-- Code Editor Frame -->
          <div class="w-full max-w-md bg-zinc-800/80 backdrop-blur-sm rounded-lg border border-zinc-700/50 shadow-2xl overflow-hidden">
            <!-- Editor Title Bar -->
            <div class="flex items-center gap-2 px-4 py-2.5 bg-zinc-800 border-b border-zinc-700/50">
              <div class="flex gap-1.5">
                <div class="w-3 h-3 rounded-full bg-red-500/80"></div>

                <div class="w-3 h-3 rounded-full bg-yellow-500/80"></div>

                <div class="w-3 h-3 rounded-full bg-green-500/80"></div>
              </div>
              <span class="text-zinc-500 text-xs font-mono ml-2">iex — ExDesk.Session</span>
            </div>
            <!-- Editor Content -->
            <div class="p-4 font-mono text-sm">
              <div class="flex items-center gap-2 text-zinc-500 text-xs mb-3">
                <.icon name="hero-chevron-right" class="size-3" /> <span>iex(1)></span>
              </div>

              <div class="text-zinc-300 flex items-center gap-1 flex-wrap">
                <span
                  class={[
                    "animate-pipeline-appear",
                    if(@has_error, do: "text-orange-400", else: "text-red-400")
                  ]}
                  style="animation-delay: 100ms"
                >
                  {pipeline_input(@has_error)}
                </span>
                <span class="text-zinc-600 animate-pipeline-appear" style="animation-delay: 300ms">
                  |>
                </span>
                <span
                  class="text-purple-400 font-bold animate-pipeline-appear"
                  style="animation-delay: 500ms"
                >
                  {pipeline_function(@has_error)}
                </span>
                <span class="text-zinc-600 animate-pipeline-appear" style="animation-delay: 700ms">
                  |>
                </span>
                <span
                  class={[
                    "animate-pipeline-appear",
                    if(@has_error, do: "text-red-500 font-bold", else: "text-green-400")
                  ]}
                  style="animation-delay: 900ms"
                >
                  {pipeline_result(@has_error)}
                </span>
              </div>
            </div>
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

            <p
              :if={@has_error}
              class="mt-4 text-sm text-error font-medium flex items-center justify-center gap-2"
            >
              <.icon name="hero-exclamation-circle" class="size-4" />
              Invalid credentials. Please check your email and password.
            </p>
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
                phx-mounted={if(!@has_error, do: JS.focus(), else: nil)}
                error_class={if(@has_error, do: "input-error ring-2 ring-error/30", else: nil)}
                class="input input-bordered input-lg w-full focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/50 rounded-xl bg-gray-50 dark:bg-zinc-900/50"
              />
              <.input
                field={@form[:password]}
                type="password"
                label="Password"
                autocomplete="current-password"
                phx-mounted={if(@has_error, do: JS.focus(), else: nil)}
                error_class={if(@has_error, do: "input-error ring-2 ring-error/30", else: nil)}
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
                <div class="relative py-3">
                  <div class="absolute inset-0 flex items-center">
                    <div class="w-full border-t-2 border-base-300/50"></div>
                  </div>

                  <div class="relative flex justify-center">
                    <span class="px-4 bg-white dark:bg-base-100 text-base-content/70 text-sm font-medium uppercase tracking-wider">
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

    has_error = Phoenix.Flash.get(socket.assigns.flash, :error) != nil
    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false, has_error: has_error)}
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

  defp pipeline_input(true), do: "Credentials"
  defp pipeline_input(false), do: "IT_Issues"

  defp pipeline_function(true), do: "ExDesk.authenticate()"
  defp pipeline_function(false), do: "ExDesk.solve()"

  defp pipeline_result(true), do: "{:error, :unauthorized}"
  defp pipeline_result(false), do: ":ok"
end
