defmodule ExDeskWeb.Router do
  use ExDeskWeb, :router

  import ExDeskWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ExDeskWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:ex_desk, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ExDeskWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", ExDeskWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{ExDeskWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm_email/:token", UserLive.Settings, :confirm_email
      live "/users/profile", UserLive.Account, :profile
      live "/users/preferences", UserLive.Account, :preferences
      live "/dashboard", DashboardLive, :index

      live "/tickets", TicketLive.Index, :index
      live "/tickets/new", TicketLive.Index, :new
      live "/tickets/:id/edit", TicketLive.Index, :edit
      live "/tickets/:id", TicketLive.Show, :show

      # Groups
      live "/groups", GroupLive.Index, :index
      live "/groups/new", GroupLive.Index, :new
      live "/groups/:id/edit", GroupLive.Index, :edit

      # Spaces
      live "/spaces", SpaceLive.Index, :index
      live "/spaces/new", SpaceLive.TemplateSelection, :new
      live "/spaces/new/:template", SpaceLive.Form, :new
      live "/spaces/:key", SpaceLive.Show, :show
      live "/spaces/:key/edit", SpaceLive.Form, :edit
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", ExDeskWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{ExDeskWeb.UserAuth, :mount_current_scope}] do
      live "/", UserLive.Login, :new
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
