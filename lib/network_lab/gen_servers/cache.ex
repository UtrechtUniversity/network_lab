
# nicked this from https://thoughtbot.com/blog/make-phoenix-even-faster-with-a-genserver-backed-key-value-store
defmodule NetworkLab.GenServers.Cache do
    use GenServer

    # iex(18)> NetworkLab.GenServers.Cache.set(:message_cache, "B", 4)
    # iex(12)> NetworkLab.GenServers.Cache.set(:message_cache, "A", %{ a: 1, b: [1, 2, 3, 4]})
    # iex(17)> NetworkLab.GenServers.Cache.fetch(:message_cache, "U", :false)
    # {:not_found, false}
    # iex(16)> NetworkLab.GenServers.Cache.fetch(:message_cache, "A", :false)
    # %{a: 1, b: [1, 2, 3, 4]}

    def start_link(opts \\ [name: "cache"]) do
        [name: name] = opts
        GenServer.start_link(__MODULE__, [
            {:ets_table_name, name},
            {:log_limit, 1_000_000}
        ], opts)
    end
  
    def fetch(pid, key, default_value) do
        case get(pid, key) do
            :not_found -> default_value
            result -> result
        end
    end
  
    def get(pid, key) do
        case GenServer.call(pid, {:get, key}) do
            [] -> :not_found
            [{_key, result}] -> result
        end
    end

    def select_by_attribute(pid, attribute, value) do
        case GenServer.call(pid, {:get, attribute, value}) do
            [] -> []
            [{_slug, result}] -> [result]
            list -> Enum.map(list, fn {_, item} -> item end)
        end
    end

    def set(pid, key, value) do
        GenServer.call(pid, {:set, key, value})
    end

    def is_member?(pid, key) do
        GenServer.call(pid, {:is_member, key})
    end

    def list_values(pid) do
        GenServer.call(pid, :list_values)
    end

    def list(pid) do
        GenServer.call(pid, :list)
    end
  
    def handle_call({:get, key}, _from, state) do
        %{ets_table_name: ets_table_name} = state
        result = :ets.lookup(ets_table_name, key)
        {:reply, result, state}
    end

    def handle_call({:get, attribute, value}, _from, state) do
        %{ets_table_name: ets_table_name} = state
        # fun = :ets.fun2ms(fn {_, %NetworkLab.Accounts.User{access_token: token}} = value when 
        #   token=="Honinbo Doetsu" -> value end)
        search_map = %{} |> Map.put(attribute, :"$1")
        search_function= [{{:_, search_map}, [{:==, :"$1", value}], [:"$_"]}]
        {:reply, :ets.select(ets_table_name, search_function) , state}
    end
  
    def handle_call({:set, key, value}, _from, state) do
        %{ets_table_name: ets_table_name} = state
        true = :ets.insert(ets_table_name,  {key, value})
        {:reply, value, state}
    end

    def handle_call({:is_member, key}, _from, state) do
        %{ets_table_name: ets_table_name} = state
        {:reply, :ets.member(ets_table_name, key), state}
    end

    def handle_call(:list_values, _from, state) do
        %{ets_table_name: ets_table_name} = state
        # fun = :ets.fun2ms(fn {_, value} -> value end) (works only in IEX, produces the $-shit below)
        {:reply, :ets.select(ets_table_name, [{{:"$1", :"$2"}, [], [:"$2"]}]) , state}
    end

    def handle_call(:list, _from, state) do
        %{ets_table_name: ets_table_name} = state
        {:reply, :ets.select(ets_table_name, [{{:"$1", :"$2"}, [], [[:"$1", :"$2"]]}]) , state}
    end

    def init(args) do
        [{:ets_table_name, ets_table_name}, {:log_limit, log_limit}] = args
        # You could introduce multiple tables here
        :ets.new(ets_table_name, [:named_table, :ordered_set, :private])
  
        {:ok, %{log_limit: log_limit, ets_table_name: ets_table_name}}
    end

end