defmodule KidsPrepWeb.Router do
  use KidsPrepWeb, :router
  import KidsPrepWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {KidsPrepWeb.Layouts, :root}
    plug :protect_from_forgery

    plug :put_secure_browser_headers, %{
      "content-security-policy" =>
        "default-src 'self'; connect-src 'self'; img-src 'self' data:; " <>
          "script-src 'self'; style-src 'self' 'unsafe-inline'; base-uri 'self'; frame-ancestors 'none'"
    }

    plug :fetch_current_user
  end

  pipeline :authenticated do
    plug :require_authenticated_user
  end

  pipeline :guest do
    plug :redirect_if_authenticated
  end

  scope "/", KidsPrepWeb do
    pipe_through [:browser, :guest]

    get "/login", SessionController, :new
    post "/login", SessionController, :create
  end

  scope "/", KidsPrepWeb do
    pipe_through :browser

    get "/logout", SessionController, :delete
  end

  scope "/", KidsPrepWeb do
    pipe_through [:browser, :authenticated]

    get "/auth/notion", NotionAuthController, :start
    get "/auth/notion/callback", NotionAuthController, :callback
    live "/", QuizLive
  end
end
