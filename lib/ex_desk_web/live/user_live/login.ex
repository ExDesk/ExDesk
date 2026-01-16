defmodule ExDeskWeb.UserLive.Login do
  use ExDeskWeb, :live_view

  alias ExDesk.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen w-full">
      <!-- Left Side (Branding) -->
      <div class="hidden lg:flex w-1/2 bg-zinc-900 relative flex-col items-center justify-center p-12 text-white overflow-hidden">
        <div class="absolute inset-0 bg-gradient-to-br from-purple-900/30 to-blue-900/10 pointer-events-none">
        </div>

        <div class="relative z-10 flex flex-col items-center max-w-lg text-center">
          <img src={~p"/images/logo.svg"} alt="ExDesk Logo" class="h-24 w-auto mb-8 drop-shadow-2xl" />
          <h1 class="text-5xl font-bold tracking-tight mb-4 text-transparent bg-clip-text bg-gradient-to-r from-purple-400 to-pink-300">
            ExDesk
          </h1>
          <p class="text-xl text-zinc-300 font-light leading-relaxed">
            The Open Source Service Desk & Asset Management Solution using the power of <span class="font-semibold text-purple-400">Elixir</span>.
          </p>
        </div>
        
    <!-- Decoration -->
        <div class="absolute bottom-0 left-0 w-full h-1/3 bg-gradient-to-t from-zinc-900/80 to-transparent">
        </div>
      </div>
      
    <!-- Right Side (Login Form) -->
      <div class="w-full lg:w-1/2 flex flex-col justify-center px-4 py-12 sm:px-6 lg:px-20 xl:px-24 bg-base-100">
        <div class="mx-auto w-full max-w-sm lg:w-96">
          <div class="text-center mb-10">
            <h2 class="mt-6 text-3xl font-extrabold text-base-content">
              Welcome back
            </h2>
            <div class="mt-2 text-sm text-base-content/70">
              <%= if @current_scope do %>
                Please reauthenticate to continue.
              <% else %>
                Don't have an account?
                <.link
                  navigate={~p"/users/register"}
                  class="font-medium text-primary hover:text-primary-focus transition-colors"
                >
                  Sign up
                </.link>
              <% end %>
            </div>
          </div>

          <div :if={local_mail_adapter?()} class="alert alert-info mb-6 shadow-sm">
            <.icon name="hero-information-circle" class="size-6 shrink-0" />
            <div>
              <p class="font-bold">Local Mail Adapter</p>
              <p class="text-sm">
                Visit <.link href="/dev/mailbox" class="underline">mailbox</.link> to see emails.
              </p>
            </div>
          </div>

          <div class="space-y-6">
            <div>
              <.form
                :let={f}
                for={@form}
                id="login_form_magic"
                action={~p"/users/log-in"}
                phx-submit="submit_magic"
                class="space-y-4"
              >
                <.input
                  readonly={!!@current_scope}
                  field={f[:email]}
                  type="email"
                  label="Email address"
                  autocomplete="email"
                  required
                  phx-mounted={JS.focus()}
                  class="input-bordered input-primary"
                />
                <.button class="btn btn-primary w-full shadow-lg shadow-primary/20">
                  Log in with email <span aria-hidden="true">→</span>
                </.button>
              </.form>
            </div>

            <div class="relative">
              <div class="absolute inset-0 flex items-center">
                <div class="w-full border-t border-base-300"></div>
              </div>
              <div class="relative flex justify-center text-sm">
                <span class="px-2 bg-base-100 text-base-content/50 uppercase tracking-wider font-semibold">
                  Or continue with
                </span>
              </div>
            </div>

            <div>
              <.form
                :let={f}
                for={@form}
                id="login_form_password"
                action={~p"/users/log-in"}
                phx-submit="submit_password"
                phx-trigger-action={@trigger_submit}
                class="space-y-4"
              >
                <.input
                  readonly={!!@current_scope}
                  field={f[:email]}
                  type="email"
                  label="Email address"
                  autocomplete="email"
                  required
                  class="input-bordered"
                />
                <.input
                  field={@form[:password]}
                  type="password"
                  label="Password"
                  autocomplete="current-password"
                  class="input-bordered"
                />

                <div class="flex items-center justify-between">
                  <div class="flex items-center">
                    <input
                      id="remember_me"
                      name={@form[:remember_me].name}
                      type="checkbox"
                      value="true"
                      class="checkbox checkbox-sm checkbox-primary rounded"
                    />
                    <label for="remember_me" class="ml-2 block text-sm text-base-content/80">
                      Remember me
                    </label>
                  </div>
                </div>

                <.button class="btn btn-neutral w-full">
                  Sign in with password
                </.button>
              </.form>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
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
