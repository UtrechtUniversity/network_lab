defmodule NetworkLabWeb.Router do
  use NetworkLabWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug NetworkLab.Auth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", NetworkLabWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/logout", SessionController, :delete
    get "/welcome", SessionController, :new

    get "/exit", ExitController, :index
    get "/subject_removed", ExitController, :removed
     
    resources "/session", SessionController, only: [:new, :create, :delete], singleton: true
    resources "/task", TaskController, only: [:index, :edit, :update]
    get "/wait", TaskController, :wait, as: :wait
  end

  scope "/admin", NetworkLabWeb do
    pipe_through :browser

    get "/", AdminController, :index
    get "/export", AdminController, :export
    get "/flush_queue", AdminController, :flush_queue
    get "/tokens", AdminController, :tokens
  end
  


  # Other scopes may use custom stacks.
  # scope "/api", NetworkLabWeb do
  #   pipe_through :api
  # end
end
