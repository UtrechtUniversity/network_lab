defmodule NetworkLab.GenServers.Initializer do
    use GenServer


    def start_link(opts \\ []) do
        GenServer.start_link(__MODULE__, nil, opts)
    end


    def init(state) do
        # CREATE EXPORT PATH
        :ok = File.mkdir_p!("tmp/exports")

        # USERS
        for user <- NetworkLab.Accounts.list_users(:db) do
            NetworkLab.GenServers.Cache.set(:user_cache, user.id, user)
        end

        # NETWORKS
        for network <- NetworkLab.Networks.list_networks(:db) do
            NetworkLab.GenServers.Cache.set(:network_cache, network.id, network)
        end

        # MESSAGES
        for message <- NetworkLab.Messages.list_messages(:db) do
            # store in cache
            NetworkLab.GenServers.Cache.set(:message_cache, message.id, message)
        end

        {:ok, state}
    end

end