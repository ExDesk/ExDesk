defmodule ExDeskWeb.Authorization do
  @moduledoc """
  Authorization helpers for LiveViews and templates.

  Provides convenient functions to check permissions and handle unauthorized access.

  ## Usage in LiveViews

      def mount(_params, _session, socket) do
        with {:ok, socket} <- authorize_or_redirect(socket, :list_all_tickets) do
          {:ok, assign(socket, tickets: Support.list_tickets())}
        end
      end

  ## Usage in Templates

      <button :if={can?(@current_user, :assign_ticket, @ticket)}>
        Assign Ticket
      </button>
  """

  import Phoenix.LiveView

  @doc """
  Checks if the current user is authorized to perform an action.

  If authorized, returns `{:ok, socket}`.
  If not authorized, redirects to home with an error flash and returns `{:halt, socket}`.

  ## Parameters

  - `socket` - The LiveView socket (must have `current_scope.user` assigned)
  - `action` - The action atom to authorize
  - `resource` - Optional resource being accessed (default: `nil`)

  ## Examples

      def mount(_params, _session, socket) do
        with {:ok, socket} <- authorize_or_redirect(socket, :manage_groups) do
          {:ok, assign(socket, groups: Support.list_groups())}
        end
      end
  """
  def authorize_or_redirect(socket, action, resource \\ nil) do
    user = get_in(socket.assigns, [:current_scope, :user])

    case Bodyguard.permit(ExDesk.Support, action, user, resource) do
      :ok ->
        {:ok, socket}

      {:error, _reason} ->
        {:halt,
         socket
         |> put_flash(:error, "Você não tem permissão para acessar esta página.")
         |> push_navigate(to: "/")}
    end
  end

  @doc """
  Checks if a user can perform an action on a resource.

  Returns `true` if authorized, `false` otherwise.
  Useful for conditionally rendering UI elements.

  ## Parameters

  - `user` - The `%User{}` struct
  - `action` - The action atom to check
  - `resource` - Optional resource being accessed (default: `nil`)

  ## Examples

      <button :if={can?(@current_user, :assign_ticket, @ticket)}>
        Assign
      </button>

      <%= if can?(@current_user, :add_internal_note, @ticket) do %>
        <textarea placeholder="Internal note..."></textarea>
      <% end %>
  """
  def can?(user, action, resource \\ nil) do
    Bodyguard.permit?(ExDesk.Support, action, user, resource)
  end

  @doc """
  Same as `can?/3` but raises if not authorized.

  Useful for handle_event callbacks where you want to fail loudly.

  ## Examples

      def handle_event("assign", %{"agent_id" => agent_id}, socket) do
        authorize!(socket.assigns.current_user, :assign_ticket, socket.assigns.ticket)
        # ... proceed with assignment
      end
  """
  def authorize!(user, action, resource \\ nil) do
    case Bodyguard.permit(ExDesk.Support, action, user, resource) do
      :ok -> :ok
      {:error, _} -> raise ExDeskWeb.UnauthorizedError, action: action
    end
  end
end

defmodule ExDeskWeb.UnauthorizedError do
  @moduledoc """
  Raised when a user attempts an unauthorized action.
  """
  defexception [:action, :message]

  @impl true
  def exception(opts) do
    action = Keyword.get(opts, :action, :unknown)
    %__MODULE__{action: action, message: "Unauthorized action: #{action}"}
  end
end
