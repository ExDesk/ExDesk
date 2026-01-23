defmodule ExDeskWeb.UserLive.Confirmation do
  use ExDeskWeb, :live_view

  def mount(%{"token" => token}, _session, socket) do
    form = to_form(%{"token" => token}, as: "user")
    {:ok, assign(socket, form: form, trigger_submit: true), temporary_assigns: [form: nil]}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <div class="text-center mb-8">
        <.header>Logging you in...</.header>

        <p class="mt-4 text-sm text-zinc-500">Please wait while we verify your magic link.</p>
      </div>

      <.form for={@form} action={~p"/users/log-in"} phx-trigger-action={@trigger_submit}>
        <.input field={@form[:token]} type="hidden" value={@form[:token].value} />
      </.form>
    </div>
    """
  end
end
