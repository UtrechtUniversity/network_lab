defmodule NetworkLab.Networks do

    import Ecto.Changeset

    alias NetworkLab.Repo
    alias NetworkLab.Networks.Network
    alias NetworkLab.GenServers.Cache
    
    import Ecto.Query, only: [from: 2, order_by: 2]
    require Logger


    def get_network(id, store \\ :cache) do
        case store do
            :cache ->
                Cache.get(:network_cache, id)
            :db ->
                Repo.get(Network, id)
        end
    end

    
    def list_networks(store \\ :cache) do
        case store do
            :db ->
                Network
                |> order_by(asc: :id)
                |> Repo.all()
            :cache ->
                Cache.list_values(:network_cache)
        end
    end


    def available_network() do
        networks = 
            list_networks()
            |> Enum.filter(fn n -> n.status == "open" end)
            |> Enum.sort(fn n1, n2 -> n1.id < n2.id end)
        case length(networks) > 0 do
            true ->
                [network | _] = networks
                network
            false ->
                false
        end
    end


    def get_control_network() do
        Enum.find(list_networks(), fn n -> n.condition_1 == "control" end)
    end


    # get users from network
    def get_users(network) do
        NetworkLab.GenServers.Cache.select_by_attribute(
            :user_cache, 
            :network_id, 
            network.id
        )
    end


    # this updates the user count of the network
    def update_network(network, params \\ %{}) do
        # create changeset
        changeset = Network.network_changeset(
            network,
            params
        )

        # store in cache
        updated_network = apply_changes(changeset)
        NetworkLab.GenServers.Cache.set(:network_cache, network.id, updated_network)
        # store async in database
        NetworkLab.GenServers.DatabaseAssistant.add(
            %{ action: "update", changeset: changeset }
        )

        # return updated network
        updated_network
    end


    # this is a helper function, it determines (based on waiting libs and cons) how many people
    # should signin before we can play
    def waiting_for_how_many_subjects(network, waiting_libs, waiting_cons) do
        half_cap = div(network.capacity, 2)
        libs = Enum.max([(half_cap - waiting_libs), 0])
        cons = Enum.max([(half_cap - waiting_cons), 0])
        Enum.max([(libs + cons), 0])
    end

end