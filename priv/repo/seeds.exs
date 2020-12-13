# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     NetworkLab.Repo.insert!(%NetworkLab.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
defmodule Seed do

    alias NetworkLab.SeedHelper

    def seed() do

        tokens_file = "priv/repo/session_16.csv"
        # used_workloads = "priv/repo/finished_workloads.csv"

        # to get access and exit tokens
        tokens = if File.exists?(tokens_file) do
            SeedHelper.read_csv_file(tokens_file)
        else
            nil
        end

        # to get access and exit tokens
        # finished_workloads = if File.exists?(used_workloads) do
        #     SeedHelper.read_csv_file(used_workloads)
        #     |> Enum.map(fn [_, _, _, id | _tail] -> String.to_integer(id) end)
        #     |> MapSet.new
        # else
        #     nil
        # end

        # FOR A PRETEST, THESE WORKLOAD-IDS ARE TO BE DISTRIBUTED OVER 
        # ALL SUBJECTS
        # lib_workload = MapSet.to_list(MapSet.difference(MapSet.new(Enum.to_list 1..450), finished_workloads))
        # cons_workload = MapSet.to_list(MapSet.difference(MapSet.new(Enum.to_list 451..900), finished_workloads))

        SeedHelper.clear()
        SeedHelper.create_admin()
        
        # SeedHelper.create_n_subjects(250, tokens, lib_workload, cons_workload)
        SeedHelper.create_n_subjects(Enum.count(tokens), tokens)

        SeedHelper.create_networks([
            # { :network_1, :homophilous, :incentive, %{ topology: :ring, capacity: 98}},
            
            # { :network_1, :random, :flat_fee, %{ topology: :hexa_lattice, rows: 16, cols: 6 }},
            { :network_2, :homophilous, :incentive, %{ topology: :hexa_lattice, rows: 16, cols: 6 }},
            
            # { :network_1, :homophilous, :flat_fee, %{ topology: :hexa_lattice, rows: 16, cols: 6 }},
            # { :network_2, :random, :flat_fee, %{ topology: :hexa_lattice, rows: 16, cols: 6 }},

            { :network_10, :control, nil, nil }

        ])
        

    end
 
end

Seed.seed()

# 9  - trial 1: homo first (done)
# 10 - trial 2: random first
# 11 - trial 3: random first
# 12 - trial 4: homo first
# 13 - trial 5: random first
# 14 - trial 6: homo first
# 15 - trial 7: homo first
# 16 - trial 8: random first






