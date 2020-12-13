defmodule NetworkLab.GenServers.NetworkAssistant do
    use GenServer

    alias NetworkLab.Accounts
    alias NetworkLab.GenServers.Cache
    alias NetworkLab.GenServers.MessageSharer
    alias NetworkLab.Messages
    alias NetworkLab.Networks
    alias NetworkLab.Propositions

    require Logger

    @no_control_messages 32

    def start_link(_) do
        queues = %{ conservative: :queue.new(), liberal: :queue.new() }
        GenServer.start_link(__MODULE__, queues, name: __MODULE__)
    end


    def add_user(user) do
        GenServer.call(__MODULE__, {:add, user})
    end


    def get_queues() do
        GenServer.call(__MODULE__, :get_queues)
    end


    def queue_status() do
        GenServer.call(__MODULE__, :queue_status)
    end


    def flush_queues_to_control() do
        GenServer.call(__MODULE__, :flush_queues_to_control)
    end


    def drop_queues() do
        GenServer.call(__MODULE__, :drop)
    end


    def init(state) do
        {:ok, state}
    end


    defp queue_lengths(queues) do
        libs = length(:queue.to_list(queues.liberal))
        cons = length(:queue.to_list(queues.conservative))
        %{ no_liberals: libs, no_conservatives: cons }
    end


    def handle_call(:get_queues, _payload, queues) do
        libs = :queue.to_list(queues.liberal)
        cons = :queue.to_list(queues.conservative)
        { :reply, %{ liberal: libs, conservative: cons }, queues }
    end


    def handle_call(:queue_status, _payload, queues) do
        { :reply, queue_lengths(queues), queues }
    end


    def handle_call({ :add, user }, _payload, queues) do

        # if a user is already assigned to a network, we assume he/she should continue
        queues = case is_integer(user.network_id) do
            # there is a network connected to this user
            true ->
                queues

            # there is no network connected to this user
            false ->

                # Network Selection
                # -----------------
                # if the data of this shubject is useless since he/she is a moderate, or fucked up
                # the ideology questions
                { network, flow } = if user.ideology == "moderate" or 
                    user.ideology == nil or 
                    String.trim("#{ user.ideology }") == "" or
                    user.ideology_conflict == true do

                    # stuff this person in control
                    { NetworkLab.Networks.get_control_network(), :irregular }
                else
                    # give me the first available network (can be anything)
                    { NetworkLab.Networks.available_network(), :regular }
                end
                

                # based on the selected network, either go to control or go to homo/random
                queues = case network.condition_1 do

                    "control" ->
                        # setup a user for control: assign user to network, assign network to user
                        # prepare messages and insert messages
                        setup_user_for_control_network(user, network)

                        # we're in the control group, that means there are no more available 
                        # non-control networks, flush queues if there are people stuck
                        log_queues(queues)

                        queues = if flow == :irregular do
                            # someone is a moderate, or there is an ideology conflict, do nothing
                            # with the queues
                            queues
                        else
                            # the flow is regular, that means this person, being a cons or lib
                            # was attached to the control network. That means all non-control networks
                            # are full, we need to flush the queue to control
                            flush_queues_to_control_network(queues, network)
                        end

                        # return the queues
                        queues

                    _ ->
                        # condition is either control or random:
                        # add this user to its appropriate queue when he/she is not part of the queue
                        queues = case user.ideology do
                            "conservative" ->
                                if Enum.member?(:queue.to_list(queues.conservative), user.id) do
                                    queues
                                else
                                    %{ queues | conservative: :queue.in(user.id, queues.conservative) }
                                end
                            "liberal" ->
                                if Enum.member?(:queue.to_list(queues.liberal), user.id) do
                                    queues
                                else
                                    %{ queues | liberal: :queue.in(user.id, queues.liberal) }
                                end
                            _ ->
                                # make it bomb proof
                                queues
                        end
                
                        # log this stuff
                        log_queues(queues)

                        # give me a count
                        no_cons = :queue.len(queues.conservative)
                        no_libs = :queue.len(queues.liberal)

                        # notify waiting channel, default waiting subjects to 1 so we never get a -1 or less
                        waiting_for = Networks.waiting_for_how_many_subjects(network, no_libs, no_cons)
                        NetworkLabWeb.Endpoint.broadcast("waiting_channel", "update", %{ waiting_for: waiting_for }) 

                        # what is half of network capacity 
                        half_capacity = div(network.capacity, 2)

                        # if we have enough to fill this network
                        if no_cons >= half_capacity && no_libs >= half_capacity do
                            # now we can unload half_capacity of our queues
                            { removed_c, remaining_c } = :queue.split(half_capacity, queues.conservative)
                            { removed_l, remaining_l } = :queue.split(half_capacity, queues.liberal)
        
                            # now we have to assign the users to the network
                            assign_user_batch_to_non_control_network(
                                network, 
                                removed_c,
                                removed_l
                            )

                            # return the remaining queues
                            %{ queues | conservative: remaining_c, liberal: remaining_l}
                        else
                            queues
                        end
                end
                queues
        end

        # admin wants to know about this
        %{ no_liberals: libs, no_conservatives: cons } = queue_lengths(queues)
        NetworkLabWeb.Endpoint.broadcast("admin_channel", "update", %{ payload: [
            %{ selector: "#queues span.libs", contents: libs },
            %{ selector: "#queues span.cons", contents: cons },
        ]}) 

        # return
        { :reply, user.id, queues }
    end


    def handle_call(:flush_queues_to_control, _payload, queues) do
        # loop over all networks
        for network <- Networks.list_networks() do
            # when the network is not control, shut it down
            unless network.condition_1 == "control" do
                # update and close down network
                Networks.update_network(network, %{ status: "closed" })
            end
        end
        # get the appropriate network
        [network |_] = Cache.select_by_attribute(:network_cache, :condition_1, "control")
        # flush them
        queues = flush_queues_to_control_network(queues, network)
        # return
        { :reply, :ok, queues }
    end



    def handle_call(:drop, _payload, _) do
        queues = %{ conservative: :queue.new(), liberal: :queue.new() }
        { :reply, :ok, queues }
    end


    defp log_queues(queues) do
        cons = :queue.to_list(queues.conservative)
        libs = :queue.to_list(queues.liberal)
        Logger.info("Network Assistent QUEUE:\nC:#{inspect(cons)}\nL:#{inspect(libs)}")
    end


    # flush everybody who's in the queues into the control network
    defp flush_queues_to_control_network(queues, network) do
        if :queue.len(queues.conservative) > 0 do
            Enum.each :queue.to_list(queues.conservative), fn user_id -> 
                # get latest state of network every time we add another user to network
                network = Networks.get_network(network.id)
                # get user
                user = Accounts.get_user!(user_id)
                # setup a user for control: assign user to network, assign network to user
                # prepare messages and insert messages
                setup_user_for_control_network(user, network)
            end
        end
        if :queue.len(queues.liberal) > 0 do
            Enum.each :queue.to_list(queues.liberal), fn user_id -> 
                # get latest state of network every time we add another user to network
                network = Networks.get_network(network.id)
                # get user
                user = Accounts.get_user!(user_id)
                # setup a user for control: assign user to network, assign network to user
                # prepare messages and insert messages
                setup_user_for_control_network(user, network)
            end            
        end
        %{ conservative: :queue.new(), liberal: :queue.new() }
    end


    # set up a user for control network
    defp setup_user_for_control_network(user, network) do

        # assign the user to the network
        params = %{
            attached_users: network.attached_users + 1,
        }
        # remove started_at if this network is a control network and it already -has- a started_at timestamp
        params = if network.started_at == nil do
             Map.put(params, :started_at, NaiveDateTime.truncate(NaiveDateTime.utc_now(),:second))
        else
            params
        end

        # returns updated network
        network = Networks.update_network(network, params)

        # admin wants know about this
        notify_admin(network)

        # assign network to the user, assign network
        user = assign_network_to_user(network, user)

        # prepare messages for control environment
        messages = if Application.get_env(:network_lab, :game_type) == :pretest do
            Messages.prepare_pretest_messages_for_user(user)
        else
            Messages.generate_control_messages_for_user(user, @no_control_messages)
        end

        # insert these messages in the cache and database
        Enum.each messages, fn m -> Messages.insert(m) end

        # return user
        user
    end





    # assigns part of the queues to a non-control network
    defp assign_user_batch_to_non_control_network(network, conservatives, liberals) do
        # convert queues to list
        conservatives = :queue.to_list(conservatives)
        liberals = :queue.to_list(liberals)

        # generate list of user ids
        user_ids = conservatives ++ liberals

        # create a user mapping
        node_mapping = case network.condition_1 do
            "random" ->
                # shuffle user_ids
                shuffled_ids = Enum.shuffle(user_ids)

                Enum.zip(Enum.to_list(1..network.capacity), shuffled_ids)
                |> Enum.sort()
                |> Enum.into(%{})

            "homophilous" ->
                # first half is conservative, second half is liberal
                Enum.zip(Enum.to_list(1..network.capacity), user_ids)
                |> Enum.sort()
                |> Enum.into(%{})
        end

        # create a node mapping
        user_mapping = Map.new(node_mapping, fn {key, val} -> {val, key} end)

        # update and close down network
        started_at = NaiveDateTime.truncate(NaiveDateTime.utc_now(),:second)
        params = %{ status: "closed", user_mapping: user_mapping, node_mapping: node_mapping,
            attached_users: length(Map.keys(user_mapping)), 
            started_at: started_at
        }

        network = Networks.update_network(network, params)

        # admin wants know about this
        notify_admin(network)

        # now communicate the network information to the users
        conservatives = Enum.map conservatives, fn user_id -> 
            user = Accounts.get_user!(user_id)
            assign_network_to_user(network, user)
        end

        liberals = Enum.map liberals, fn user_id -> 
            user = Accounts.get_user!(user_id)
            assign_network_to_user(network, user)
        end

        # select appropriate messages for users in network batch: pretest <-> not pretest
        messages = if Application.get_env(:network_lab, :game_type) == :pretest do

            # collect all users       
            all_users = conservatives ++ liberals

            # generate pretest messages for all users
            Enum.map all_users, fn u -> Messages.prepare_pretest_messages_for_user(u) end

        else

            # setup messages: THIS IS FOR THE LIBERALS
            props_libs = Enum.filter(Propositions.list_propositions(), fn p ->
                p.lib == 1
            end)
            # AND THIS IS FOR THE CONSERVATIVES
            props_cons = Enum.filter(Propositions.list_propositions(), fn p -> 
                p.lib == 0
            end)

            # get appropriate number of subjects
            selected_libs = Enum.take_random(liberals, length(props_libs))
            selected_cons = Enum.take_random(conservatives, length(props_cons))

            # zip the props with subjects, and add them
            subjects_props = Enum.zip(selected_libs, props_libs) ++ Enum.zip(selected_cons, props_cons)

            # divide propositions list in chunks and assigns the chunks as messages to users
            Enum.map subjects_props, fn { user, prop } -> 
                # this is fucking weird, but the scientists have decided that the seed guy
                # shares the message without actually sharing it! Oh! And yes! The 'shared' 
                # message must be hidden for the seed-user (sender_id = nil will be an indicator 
                # to hide this message in the front end). Great
                message = Messages.create_message_for_user(
                    user: user, 
                    proposition: prop,
                    version: :show_version,
                    decision: "share"
                )
                # Share
                MessageSharer.share(user, message, false)
                # and return the message
                message
            end

        end

        # flatten messages list
        messages = List.flatten(messages)

        # insert these messages in the cache and database
        Enum.each messages, fn m -> Messages.insert(m) end

        # return network
        network
    end


    defp notify_admin(network) do
        # admin wants know about this
        NetworkLabWeb.Endpoint.broadcast("admin_channel", "update", %{ payload: [
            %{ selector: "#network-#{network.id} td.attached-users", contents: network.attached_users },
            %{ selector: "#network-#{network.id} td.status", contents: network.status }
        ]})
    end


    # assigns network information to the user
    defp assign_network_to_user(network, user, started_at \\ nil) do
        { node_id, neighbour_ids, neighbour_info } = case network.condition_1 do
           "control" ->
                { nil, nil, nil }
            _ ->
                node_id = network.user_mapping[user.id]
                neighbours = Enum.map network.neighbour_mapping[node_id], fn nid ->
                    Accounts.get_user(network.node_mapping[nid])
                end
                neighbour_ids = Enum.map(neighbours, fn n -> n.id end)
                neighbour_info = Enum.into(
                    Enum.map(neighbours, fn n -> { n.username, n.ideology } end),
                    %{}
                )
                { node_id, neighbour_ids, neighbour_info }
        end

        condition_2 = case network.condition_1 do
            "control" -> 
                case user.ideology_conflict do
                    true -> "flat_fee"
                    false -> Enum.random(["flat_fee", "incentive"])
                end
            _ -> network.condition_2
        end

        params = %{
            status: "playing",
            condition_1: network.condition_1,
            condition_2: condition_2,
            network_id: network.id,
            node_id: node_id,
            neighbour_ids: neighbour_ids,
            neighbour_info: neighbour_info,
            started_at: started_at || NaiveDateTime.truncate(NaiveDateTime.utc_now(),:second)
        }

        user = Accounts.attach_user_to_network(user, params)

        # admin wants know about this
        NetworkLabWeb.Endpoint.broadcast("admin_channel", "update", %{ payload: [
            %{ selector: "#user-#{user.id} td.status", contents: user.status },
            %{ selector: "#user-#{user.id} td.condition-1", contents: user.condition_1 },
            %{ selector: "#user-#{user.id} td.condition-2", contents: user.condition_2 },
        ]})

        # reveal stuff on the waiting page
        NetworkLabWeb.Endpoint.broadcast("user:#{user.id}", "reveal_instructions", %{
            condition_1: user.condition_1,
            condition_2: user.condition_2
        })         

        # return updated user
        user
    end

end