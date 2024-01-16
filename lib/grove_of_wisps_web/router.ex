defmodule GroveOfWispsWeb.Router do
  use GroveOfWispsWeb, :router

  import GroveOfWispsWeb.UsersAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {GroveOfWispsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_users
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", GroveOfWispsWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", GroveOfWispsWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:grove_of_wisps, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: GroveOfWispsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", GroveOfWispsWeb do
    pipe_through [:browser, :redirect_if_users_is_authenticated]

    live_session :redirect_if_users_is_authenticated,
      on_mount: [{GroveOfWispsWeb.UsersAuth, :redirect_if_users_is_authenticated}] do
      live "/user/register", UsersRegistrationLive, :new
      live "/user/log_in", UsersLoginLive, :new
      live "/user/reset_password", UsersForgotPasswordLive, :new
      live "/user/reset_password/:token", UsersResetPasswordLive, :edit
    end

    post "/user/log_in", UsersSessionController, :create
  end

  scope "/", GroveOfWispsWeb do
    pipe_through [:browser, :require_authenticated_users]

    live_session :require_authenticated_users,
      on_mount: [{GroveOfWispsWeb.UsersAuth, :ensure_authenticated}] do
      live "/user/settings", UsersSettingsLive, :edit
      live "/user/settings/confirm_email/:token", UsersSettingsLive, :confirm_email
    end
  end

  scope "/", GroveOfWispsWeb do
    pipe_through [:browser]

    delete "/user/log_out", UsersSessionController, :delete

    live_session :current_users,
      on_mount: [{GroveOfWispsWeb.UsersAuth, :mount_current_users}] do
      live "/user/confirm/:token", UsersConfirmationLive, :edit
      live "/user/confirm", UsersConfirmationInstructionsLive, :new
    end
  end
end
