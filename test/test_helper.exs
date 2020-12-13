ExUnit.start()

# https://elixirforum.com/t/issues-running-tests-with-a-phoenix-1-3-app-that-uses-genserver-processes/12696
# https://medium.com/@qertoip/making-sense-of-ecto-2-sql-sandbox-and-connection-ownership-modes-b45c5337c6b7

# Ecto.Adapters.SQL.Sandbox.mode(NetworkLab.Repo, :manual)
Ecto.Adapters.SQL.Sandbox.mode(NetworkLab.Repo, :auto)

{ :ok, _ } = Application.ensure_all_started(:wallaby)
Application.put_env(:wallaby, :base_url, NetworkLabWeb.Endpoint.url)
