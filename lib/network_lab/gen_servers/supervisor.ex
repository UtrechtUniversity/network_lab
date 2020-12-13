defmodule NetworkLab.GenServers.Supervisor do
    use Supervisor

    def start_link(_) do
        Supervisor.start_link(__MODULE__, :ok, name: :genserver_supervisor)
    end

    @impl true
    def init(:ok) do
        children = [
            Supervisor.child_spec({NetworkLab.GenServers.Cache, name: :message_cache}, id: :message_cache),
            Supervisor.child_spec({NetworkLab.GenServers.Cache, name: :user_cache}, id: :user_cache),
            Supervisor.child_spec({NetworkLab.GenServers.Cache, name: :network_cache}, id: :network_cache),
            Supervisor.child_spec({NetworkLab.GenServers.Cache, name: :share_cache}, id: :share_cache),
      
            NetworkLab.GenServers.NetworkAssistant,
            NetworkLab.GenServers.DatabaseAssistant,
            NetworkLab.GenServers.Exporter,
            NetworkLab.GenServers.MessageSharer,
            NetworkLab.GenServers.NetworkTimer,
            NetworkLab.GenServers.Initializer,
        ]
  
        Supervisor.init(children, strategy: :one_for_one)
    end

end