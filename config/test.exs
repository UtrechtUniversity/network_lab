use Mix.Config


# Configure your database
config :network_lab, NetworkLab.Repo,
  username: "casper",
  password: "",
  database: "network_lab_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  ownership_timeout: 100_000

  
# We don't run a server during test. If one is required,
# you can enable the server option below.
config :network_lab, NetworkLabWeb.Endpoint,
  http: [port: 4002],
  server: true

# this is added for Wallaby
config :network_lab, :sql_sandbox, true
config :wallaby, screenshot_dir: "test/screenshots"
config :network_lab, screenshot_on_failure: true

# Print only warnings and errors during test
config :logger, level: :warn
