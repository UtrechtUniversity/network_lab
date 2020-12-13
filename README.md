# NetworkLab

# 1. Create a token file:

Make sure to run $mix compile$ if you change the Task file (in lib/mix/tasks)

$ mix create_tokens --n=600 --path=priv/repo/session_9.csv

# 2. Change seeds.ex file accordingly (/priv/repo/seeds.exs)

# 3. Reset database

$ mix ecto.rollback --all ; mix ecto.migrate ; mix run priv/repo/seeds.exs

# 4. Run phoenix app

$ iex -S mix phx.server



