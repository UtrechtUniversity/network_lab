defmodule NetworkLab.GenServers.MessageSharer do
    use GenServer

    alias NetworkLab.Accounts
    alias NetworkLab.Messages
    alias NetworkLab.Networks

    def start_link(_) do
        GenServer.start_link(__MODULE__, nil, name: __MODULE__)
    end


    def share(user, message, broadcast \\ true) do
        GenServer.cast(__MODULE__, {:share, user, message, broadcast})
    end


    def init(state) do
        {:ok, state}
    end


    def handle_cast({:share, user, message, broadcast}, state) do

        # only allow messaging if the network allows it
        network = Networks.get_network(user.network_id)

        if network.allow_messaging == true do

            # add to share cache
            NetworkLab.Shares.cache_share(user, message)

            # iterate over all neighbours
            for n_id <- user.neighbour_ids do
                # get neighbour
                neighbour = Accounts.get_user(n_id)
                # get all messages from this neighbour
                n_messages = Messages.list_receiver_messages(neighbour)
                # get proposition_ids of these messages
                prop_ids = Enum.map n_messages, fn m -> m.proposition_id end

                # if the neighbour does NOT have this message, AND the user is not finished...
                if Enum.member?(prop_ids, message.proposition_id) == false && neighbour.status != "finished" do
                    # create a new message
                    new_message = %{ message |
                        sender_id: user.id, 
                        receiver_id: neighbour.id, 
                        decision: nil, 
                        decision_made_at: nil 
                    }
                    # insert
                    new_message = Messages.insert(new_message)

                    # and broadcast
                    if broadcast == true do
                        # create HTML to broadcast
                        broadcast_message = Phoenix.View.render_to_string(
                            NetworkLabWeb.TaskView,
                            "_message.html", 
                            message: new_message,
                            user: neighbour
                        )
                        # broadcast
                        NetworkLabWeb.Endpoint.broadcast(
                            "user:#{neighbour.id}", 
                            "incoming_shared_message", 
                            %{ contents: broadcast_message }
                        )
                    else
                        :ok
                    end
                end
            end

        else
            # IO.puts("NO SHARING!!!!")
        end

        # and return async
        { :noreply, state}
    end

end