# GIT branches
$ git push --set-upstream origin pretest
$ git push --set-upstream origin master

# PzkPTN0yB5
# 8hvuR5CiJU
# aj1Or8Cqxe


# Production

* push app to render.com, that will build up everything, seeds, etc
* go to shell on render.com
* run: _build/prod/rel/network_lab/bin/network_lab remote
# run simulator
$ mix ecto.rollback --all ; mix ecto.migrate ; mix run priv/repo/seeds.exs
$ iex -S mix phx.server      
$ NetworkLab.Simulator.signin(190)
$ NetworkLab.Simulator.sim_almost_all_players([453])

Application.get_env(:network_lab, NetworkLab.Repo)[:pool_size]

* backup database, I have an external connection string: 
PGPASSWORD=glJicqqtNs4gxpbSzxx0RlD2HFj5yFEe pg_dump -h postgres.render.com -Fc -o -U  networklab_user networklab > render.com.dump.sql
???

* connect to database
PGPASSWORD=glJicqqtNs4gxpbSzxx0RlD2HFj5yFEe psql -h postgres.render.com -U networklab_user networklab


# Migration

* mix ecto.gen.migration create_networks_table
* edit priv > repo > migrations > <latest_file>
* mix ecto.migrate
* create context folder, within folder puts schema-file + changesets, and outside context folder an "entrypoint"
* mix ecto.rollback -> for a rollback


# Seeds
* mix run priv/repo/seeds.exs



# Add dependencies to mix file:

* add dependency to ~/mix.exs (Phoenix 'bundle' file)
* mix deps.get




# Adding an array in Postgres

* migration: add :user_ids, { :array, :integer }, default: fragment("ARRAY[]::integer[]")
* schema: field :user_ids, {:array, :integer}
* when printed, lists like [120, 121] might look like 'xy', just because they have the wrong ASCII values. Weird.


  583  mix ecto.rollback
  584  mix ecto.migrate
  585  mix ecto.migrate
  586  mix run priv/repo/seeds.exs 
  mix ecto.rollback --all

  