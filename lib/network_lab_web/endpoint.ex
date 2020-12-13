defmodule NetworkLabWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :network_lab

  # socket "/socket", NetworkLabWeb.UserSocket,
  #   websocket: true,
  #   longpoll: false

  # Endpoint that handles authenticated socket traffic
  socket "/auth_socket", NetworkLabWeb.AuthSocket,
    websocket: true,
    longpoll: false

  # THIS IS FOR WALLABY
  if Application.get_env(:network_lab, :sql_sandbox) do
    plug Phoenix.Ecto.SQL.Sandbox
  end

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :network_lab,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session,
    store: :cookie,
    key: "_network_lab_key",
    signing_salt: "V6gMRe0d"

  plug NetworkLabWeb.Router
end
