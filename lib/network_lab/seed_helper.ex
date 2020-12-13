defmodule NetworkLab.SeedHelper do

    alias NetworkLab.Repo
    alias NetworkLab.Accounts.User
    alias NetworkLab.Networks.Network
    alias NetworkLab.Messages.Message
    alias NimbleCSV.RFC4180, as: CSV

    require Logger

    @chars "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" |> String.codepoints

    # clear database tables
    def clear do
        Repo.delete_all(User)
        Repo.delete_all(Network)
        Repo.delete_all(Message)
    end
    

    # generate a random string of length <length>
    def generate_rand_string(length) do
        # :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
        Enum.reduce((1..length), [], fn (_i, acc) ->
            [ Enum.random(@chars) | acc ]
        end) |> Enum.join("")
    end


    # create an admin user
    def create_admin() do
        user = %User{ 
            username: "admin",
            role: "admin",
            access_token: "ro11thed1c3",
            exit_token: "yo'mama"
        }
        NetworkLab.Repo.insert!(user)
    end


    # create a certain amount of participants with unique access tokens
    def create_n_subjects(n, tokens \\ [], lib_workloads \\ [], cons_workloads \\ []) do
        # tokens have size 10
        size = 10
        tokens_count = Enum.count(tokens)

        # do something with the workloads to avoid warnings
        _tmp = lib_workloads ++ cons_workloads

        token_combinations =  if tokens_count > 0 do
            if is_range(n) do
                if tokens_count < Enum.count(n) do
                    raise "Amount of tokens is smaller than amount of subjects"
                else
                    Enum.slice(tokens, n)
                end
            else 
                if tokens_count < n do
                    raise "Amount of tokens is smaller than amount of subjects"
                else
                    Enum.slice(tokens, 0..n)
                end
                
            end
        else
            create_n_token_combinations(n, size)
        end

        # shuffle workloads
        #lib_workloads = Enum.shuffle lib_workloads
        #cons_workloads = Enum.shuffle cons_workloads

        # prepare the user accounts
        Enum.map Enum.with_index(token_combinations), fn { [access_token, exit_token], i } ->

            # workload = if Application.get_env(:network_lab, :game_type) == :pretest do
            #     lwl = Enum.at(lib_workloads, rem(i, Enum.count(lib_workloads))) || Enum.random(lib_workloads)
            #     cwl = Enum.at(cons_workloads, rem(i, Enum.count(cons_workloads))) || Enum.random(cons_workloads)
            #     %{
            #         "liberal" => lwl,
            #         "conservative" => cwl,
            #         "moderate" => Enum.random([lwl, cwl]),
            #     }
            # else
            #     nil
            # end

            workload = nil

            # create user struct
            user = %User{ 
                username: "user_#{i + 1}",
                role: "subject",
                access_token: access_token,
                exit_token: exit_token,
                workload: workload
            }
            # insert
            NetworkLab.Repo.insert!(user)
        end

    end


    def create_n_token_combinations(n, size \\ 8) do
        # no tokens, generate them
        length = if is_range(n) do
            Enum.count(n)
        else
            n
        end

        access_tokens = Enum.reduce_while 1..length, [], fn _, acc ->
            if Enum.count(acc) >= length do
                { :halt, acc }
            else
                access_token = generate_rand_string(size)
                if Enum.member?(acc, access_token) do
                    { :cont, acc }
                else
                    { :cont, [ access_token | acc ]}
                end
            end
        end

        Enum.map access_tokens, fn token ->
            [token, generate_rand_string(size)]
        end
    end


    # create networks according to list
    def create_networks(networks \\ []) do
        for { name, condition_1, condition_2, specs } <- networks do
            { neighbour_mapping, capacity, topology } = if condition_1 != :control do
                create_topology(specs)
            else
                { nil, nil, "none" }
            end
            
            network = %Network{
                name: Atom.to_string(name),
                condition_1: Atom.to_string(condition_1),
                condition_2: Atom.to_string(condition_2),
                topology: topology,
                capacity: capacity,
                neighbour_mapping: neighbour_mapping,
            }

            # insert
            NetworkLab.Repo.insert!(network)
        end
    end


    # this function takes an amount of rows and cols and creates a map of node_ids
    # as keys, and a list containing their neighbour ids as values
    defp create_topology(specs) do
        %{ topology: topology } = specs

        { neighbour_mapping, capacity } = case topology do
            :ring -> create_ring_topo(specs)
            :hexa_lattice -> create_hexa_lattice(specs)
        end

        { Enum.into(neighbour_mapping, %{}), capacity, Atom.to_string(topology) }
    end


    defp create_hexa_lattice(specs) do

        %{ rows: rows, cols: cols } = specs
        capacity = rows * cols

        nodes = Enum.to_list(1..capacity)
        matrix = nodes |> Enum.chunk_every(cols)

        neighbour_mapping = Enum.map Enum.with_index(nodes), fn { item, index } ->
            row = div(index, cols)
            col = rem(index, cols)

            up_left = get_value_in_pseudo_matrix(matrix, { row - 1, col - 1 }, specs)
            up = get_value_in_pseudo_matrix(matrix, { row - 1, col }, specs)
            up_right = get_value_in_pseudo_matrix(matrix, { row - 1, col + 1 }, specs)
            below_left = get_value_in_pseudo_matrix(matrix, { row + 1, col - 1 }, specs)
            below = get_value_in_pseudo_matrix(matrix, { row + 1, col }, specs)
            below_right = get_value_in_pseudo_matrix(matrix, { row + 1, col + 1 }, specs)

            { item, [up_left, up, up_right, below_left, below, below_right] }
        end

        { neighbour_mapping, capacity }
    end


    # This is for the hexa_lattice, it takes a list of lists, representing a 
    # matrix and finds the value at { row, col } = coords
    defp get_value_in_pseudo_matrix(list, coords, specs) do
        { row, col } = coords
        %{ rows: rows, cols: cols } = specs

        row = rem(row, rows)
        col = rem(col, cols)

        selected_row = Enum.at list, row
        Enum.at selected_row, col
    end


    defp create_ring_topo(specs) do

        capacity = specs[:capacity]
        nodes = Enum.to_list(1..capacity)

        neighbour_mapping = for { item, index } <- Enum.with_index(nodes) do
            left_3 = Enum.at(nodes, index - 3)
            left_2 = Enum.at(nodes, index - 2)
            left_1 = Enum.at(nodes, index - 1)
            right_1 = Enum.at(nodes, rem(index + 1, capacity))
            right_2 = Enum.at(nodes, rem(index + 2, capacity))
            right_3 = Enum.at(nodes, rem(index + 3, capacity))
            { item, [left_3, left_2, left_1, right_1, right_2, right_3] }
        end

        { neighbour_mapping, capacity }
    end


    def read_csv_file(filepath, omit_header \\ false) do
        contents =
            filepath
            |> File.read!()
            |> CSV.parse_string

        result = if omit_header do
            [ _ | tail ] = contents
            tail
        else
            contents
        end

        result
    end


    defp is_range(%Range{}), do: true
    defp is_range(_), do: false

end