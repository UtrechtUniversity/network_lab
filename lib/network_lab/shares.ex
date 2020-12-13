defmodule NetworkLab.Shares do

    alias NetworkLab.GenServers.Cache

    def cache_share(user, message) do
        key = create_key(user, message)

        values = get(key)
        new_values = Map.put(values, user.username, user.ideology)
        # set the new value
        Cache.set(:share_cache, key, new_values)
    end


    def get(key) do
        case Cache.get(:share_cache, key) do
            :not_found -> %{}
            result -> result
        end
    end


    def get(user, message) do
        key = create_key(user, message)
        get(key)
    end


    def list_shares() do
        Enum.map Cache.list(:share_cache), fn [key, map] ->
            network_key = String.split(key, "_", trim: true)
            network_key ++ Map.keys(map)
        end
    end


    defp create_key(user, message) do
        network = user.network_id
        proposition = message.proposition_id
        "#{ network }_#{ proposition}"
    end

end
