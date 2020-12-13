defmodule NetworkLab.GenServers.Exporter do
    use GenServer

    # THIS GENSERVER MAKES NO SENSE, 
    # but I have created it nonetheless because I am afraid that gathering the data takes more than 
    # 60 secs, the timout from Cowboy. With a Genserver I can make it an async-thing and notify/broadcast
    # the browser to pop-up a button or something if the export is ready. In this particular case
    # it isn't necessary, but I will keep it as it is for now. In other words: this is a very complicated
    # piece of code for nothing.
    # Note the timeout on the call for create_eport_file, it is set to 40 secs

    alias NetworkLab.Accounts
    alias NetworkLab.Messages
    alias NetworkLab.Networks
    alias NetworkLab.Shares
    alias NetworkLab.Propositions
    alias NetworkLab.PretestWorkloads
    alias NimbleCSV.Spreadsheet, as: CSV

    def start_link(_) do
        GenServer.start_link(__MODULE__, nil, name: __MODULE__)
    end

    def create_export_file(file_name) do
        # call with timeout set at 40 secs
        GenServer.call(__MODULE__, {:create_export_file, file_name}, 40_000)
    end

    def init(state) do
        {:ok, state}
    end

    def handle_call({:create_export_file, file_name}, _payload, state) do

        path = "tmp/exports"

        workloads = 
            PretestWorkloads.list_workloads()
            |> Enum.map(fn { key, [ideology | [workload]] } ->
                [key, ideology] ++ Enum.reduce(workload, [], fn { id, _, version }, acc -> acc ++ [ id, version ] end)
            end)
            |> Enum.sort

        workloads = 
            [["id", "ideology"] ++ 
                Enum.reduce(1..24, [], fn i, acc -> acc ++ ["prop_id_#{i}", "version_#{i}"] end) | workloads]

        File.write!("#{path}/workloads.csv", convert_to_csv(workloads))


        # create dumps of all resources
        users = 
            Accounts.list_subjects()
            |> Enum.map(fn row ->
               [row.id, row.username, row.agreed_to_terms, row.agreed_to_personal_data,
               row.started_at, row.status, row.condition_1, row.condition_2, 
               row.alleged_ideology, row.current_ideology, row.ideology_conflict, row.ideology, 
               row.access_token, row.exit_token, row.network_id, row.node_id] ++
               [row.workload["liberal"], row.workload["conservative"], row.workload["moderate"]] ++
               (row.neighbour_ids || [nil, nil, nil, nil, nil, nil])
            end)
        users = [["id", "username", "agreed_to_terms", "agreed_to_personal_data",
            "started_at", "status", "condition_1", "condition_2", 
            "alleged_ideology", "current_ideology", "ideology_conflict", "ideology", 
            "access_token", "exit_token", "network_id", "node_id", 
            "workload_lib", "workload_cons", "workload_moderate",
            "id_n1", "id_n2", "id_n3", "id_n4", "id_n5", "id_n6"] | users]
        File.write!("#{path}/users.csv", convert_to_csv(users))

        networks =
            Networks.list_networks()
            |> Enum.map(fn row ->
                [row.id, row.name, row.condition_1, row.condition_2, row.status, row.capacity, 
                    row.attached_users]
            end)
        networks = [["id", "name", "condition_1", "condition_2", "status", "capacity", "attached_users"] | networks]
        File.write!("#{path}/networks.csv", convert_to_csv(networks))

        topo = get_topo_data(Networks.list_networks())
        File.write!("#{path}/topo.csv", convert_to_csv(topo))

        shares = Shares.list_shares()
        File.write!("#{path}/shares.csv", convert_to_csv(shares))

        propositions =
            Propositions.list_propositions()
            |> Enum.map(fn row -> 
                [row.id, row.title, Map.get(row, String.to_existing_atom("true")), 
                    Map.get(row, String.to_existing_atom("false")), 
                    row.post_is_false, row.post_intended_as_liberal,
                    row.show_version, row.fake, row.lib
                ]
            end)
        propositions = [["id", "title", "true", "false", "post_is_false", "post_intended_as_liberal",
                        "shown_version", "fake", "lib"] | propositions]
        File.write!("#{path}/propositions.csv", convert_to_csv(propositions))

        messages =
            Messages.list_messages()
            |> Enum.map(fn row ->
                [row.id, row.network_id, row.sender_id, row.receiver_id, row.proposition_id, 
                row.proposition_type, row.proposition_title, row.proposition, row.decision,
                row.decision_made_at, row.inserted_at, row.updated_at]
            end)
        messages = [["id", "network", "sender_id", "receiver_id", "prop_id", "prop_type",
                    "prop_title", "proposition_text", "decision", "decision_made_at",
                    "inserted_at", "updated_at"] | messages]
        File.write!("#{path}/messages.csv", convert_to_csv(messages))


        # zip the files
        zip_file = "#{path}/#{file_name}.zip"
        files =
            File.ls!(path)
            |> Enum.filter(fn f -> Path.extname(f) == ".csv" end)
            |> Enum.map(&String.to_charlist/1)
        :zip.create(zip_file, files, cwd: path)

        { :reply, zip_file, state }
    end

    # 
    def get_topo_data(all_networks) do
        # add node_mapping and neighbours in 1 matrix for every network
        result = Enum.map all_networks, fn network ->
            node_mapping = if network.node_mapping do
                [ ["node_id", "user_id" ] | convert_map_into_list(network.node_mapping) ]
            end
            neighbours = if network.neighbour_mapping do
                [ ["node_id_copy", "id_n1", "id_n2", "id_n3", "id_n4", "id_n5", "id_n6"] | 
                    convert_map_into_list(network.neighbour_mapping) ]
            end
            table = if node_mapping != nil and neighbours != nil do
                network_id = [ ["network_id"] | Enum.map((1..network.capacity), fn _ -> [network.id] end)]
                zipped = Enum.zip([network_id, node_mapping, neighbours])
                Enum.map zipped, fn { v1, v2, v3 } -> v1 ++ v2 ++ v3 end
            end
            table
        end
        # remove all nil's
        result = Enum.reject(result, &is_nil/1)
        # if there is more than 1 network, remove the headers for every network, 1 header is enough
        result = if length(result) > 1 do
            [head | tail] = result
            tail = Enum.map(tail, fn [_h|t] -> t end)
            [head | tail]
        else 
            result
        end
        # combine data from all networks in 1 matrix
        Enum.concat result
    end

    # convert data into a legit csv format, uncluding a BOM
    defp convert_to_csv(data) do
        data
        |> CSV.dump_to_iodata()
        |> IO.iodata_to_binary
    end

    # converts key, value map into a list with every row [[k, v1], [k, v2], ...]
    # if value is a list -> [[k, v11, v12, v13], [k, v21, v22, v23], ...]
    defp convert_map_into_list(mapping) do
        result = Enum.map mapping, fn {k, v} ->
            case is_list(v) do
                true -> [k] ++ v
                false -> [k, v]
            end
        end
        Enum.sort(result)
    end


end