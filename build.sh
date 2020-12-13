#!/usr/bin/env bash

# https://render.com/docs/deploy-phoenix
# https://alchemist.camp/articles/elixir-releases-deployment-render

# exit on error
set -o errexit

# Initial setup
mix deps.get --only prod
MIX_ENV=prod mix compile

echo "part 1"

echo "reset database, migrate, push data in database with seeds"
# mix ecto.reset
mix ecto.migrate

echo "done migrating, run seeds"

mix run priv/repo/seeds.exs

echo "1a"

# Compile assets
npm install --prefix ./assets

echo "1b"

# FOR THIS YOU NEED WEBPACK
# => in de /assets folder run:
# npm install --save-dev webpack
# npm install --save-dev webpack-cli
npm run deploy --prefix ./assets

echo "part 2"

mix phx.digest

echo "part 3"


# Build the release and overwrite the existing release directory
MIX_ENV=prod mix release --overwrite

echo "part 4"

# Release created at _build/prod/rel/network_lab!

#     # To start your system
#     _build/prod/rel/network_lab/bin/network_lab start

# Once the release is running:

#     # To connect to it remotely
#     _build/prod/rel/network_lab/bin/network_lab remote

#     # To stop it gracefully (you may also send SIGINT/SIGTERM)
#     _build/prod/rel/network_lab/bin/network_lab stop

# To list all commands:

#     _build/prod/rel/network_lab/bin/network_lab