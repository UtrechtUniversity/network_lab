defmodule NetworkLab.GenServers.NetworkTimer do
    use GenServer

    alias NetworkLab.GenServers.Cache
    alias NetworkLab.Accounts
    alias NetworkLab.Networks

    # tick interval is every 5 seconds
    @tick_interval 5_000
    
    def start_link(_) do
        GenServer.start_link(__MODULE__, nil, name: __MODULE__)
    end


    def init(state) do
        tick()
        {:ok, state}
    end


    def handle_info(:tick, state) do

        # this is for the 8 mins regular game duration (in secs)
        game_duration = Application.get_env(:network_lab, :game_duration)
        # this is for the 11 mins total playing time (in secs)
        game_ends = Application.get_env(:network_lab, :game_ends)

        for network <- Cache.list_values(:network_cache) do

            # if the network was started
            unless network.started_at == nil || network.condition_1 == "control" do
                
                # what was the start time
                start = network.started_at
                # current time
                now = NaiveDateTime.utc_now()
                # what is the time difference in minutes plus remaining seconds
                elapsed = NaiveDateTime.diff(now, start, :second)

                # if elapsed time exceeded @early_finish but before @late_finish time
                if elapsed >= game_duration and elapsed < game_ends do

                    # stop messaging if necessary
                    if network.allow_messaging == true do
                        Networks.update_network(network, %{ allow_messaging: false })
                    end

                    # this is for users who are done before 8 mins and are waiting for new messages
                    # get all users of this network -> 
                    users = Cache.select_by_attribute(:user_cache, :network_id, network.id)
                    # and filter for the unfinished ones
                    unfinished = Enum.filter users, fn user -> user.status != "finished" end
                    # if there are finished people they have to get an exit token
                    Enum.each unfinished, fn user ->
                        # get messages
                        messages = Cache.select_by_attribute(:message_cache, :receiver_id, user.id)
                        # how many of those are not decided on
                        undecided = Enum.count messages, fn message -> message.decision == nil end
                        # if there are 0 undecided messages, this user is done
                        if undecided == 0 do
                            finish_user(user)
                        end
                    end
                end

                # make sure everybody who didn't finish yet, will finish asap
                if elapsed >= game_ends do

                    # get all users who answered all their messages
                    users = Cache.select_by_attribute(:user_cache, :network_id, network.id)
                    # who's not finished yet
                    unfinished = Enum.filter users, fn user -> user.status != "finished" end
                    # make these people finish
                    Enum.each unfinished, fn user ->
                        finish_user(user, "dropped")
                    end
                end

            end
        end

        # ask for the tick
        tick()

        # and return async
        { :noreply, state }
    end


    defp finish_user(user, status \\ "finished") do
        # set user status
        user = Accounts.update_user_status(user, status)
        # broadcast this to user
        NetworkLabWeb.Endpoint.broadcast("user:#{user.id}", "finish", %{})
        # broadcast to admin as well
        NetworkLabWeb.Endpoint.broadcast("admin_channel", "update", %{ payload: [
            %{ selector: "#user-#{user.id} td.status", contents: user.status }
        ]})
    end


    defp tick() do
        # wait @tick_interval seconds to continue
        Process.send_after(self(), :tick, @tick_interval)
    end

end