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
defmodule Mix.Tasks.CreateTokens do
    use Mix.Task

    alias NetworkLab.SeedHelper
    alias NimbleCSV.RFC4180, as: CSV

    @shortdoc "Create log-in tokens"

    @impl Mix.Task
    def run(args) do
        { parsed, _args, _invalid } = OptionParser.parse(
            args, 
            strict: [n: :integer, path: :string]
        )

        parsed = Enum.into(parsed, %{})
        
        parsed = case Map.has_key? parsed, :n do
            false -> Map.put(parsed, :n, 200)
            _ -> parsed
        end

        parsed = case Map.has_key? parsed, :path do
            false -> Map.put(parsed, :path, "priv/repo/session.csv")
            _ -> parsed
        end

        tokens = 
            [ ["access token", "exit token"] | SeedHelper.create_n_token_combinations(parsed.n, 10) ]
            |> CSV.dump_to_iodata()
            |> IO.iodata_to_binary
        File.write!("#{parsed.path}", [tokens])

    end
end

# TokensFile.create_access_token_file(400, "priv/repo/session_8.csv")