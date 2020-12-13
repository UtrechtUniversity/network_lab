# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :network_lab,
  ecto_repos: [NetworkLab.Repo],
  # this is to distinguish between pretest and regular
  game_type: :regular,
  # game_type: :pretest,
  game_duration: 8 * 60,
  game_ends: 11 * 60,
  game_env: :real, #:test,
  ideologies: [
    { "1", "extremely liberal", "liberal" },
    { "2", "liberal", "liberal" },
    { "3", "slightly liberal", "liberal" },
    { "4", "moderate, middle of the road", "moderate" },
    { "5", "slightly conservative", "conservative" },
    { "6", "conservative", "conservative" },
    { "7", "extremely conservative", "conservative" },
  ]

# Configures the endpoint
config :network_lab, NetworkLabWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "fO+yaxxQovKLDqZVVZ58nsmYCW4gshHbnm+KLg11LvyhEQjWcSuHL8B6TwTDCfrg",
  render_errors: [view: NetworkLabWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: NetworkLab.PubSub, adapter: Phoenix.PubSub.PG2]


# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
