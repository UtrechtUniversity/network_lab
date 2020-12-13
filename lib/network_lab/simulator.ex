defmodule NetworkLab.Simulator do

    alias NetworkLab.Accounts
    alias NetworkLab.Messages
    alias NetworkLab.Networks
    alias NetworkLab.Propositions
    alias NetworkLab.GenServers.Cache
    alias NetworkLab.GenServers.NetworkAssistant
    alias NetworkLab.GenServers.DatabaseAssistant, as: DBA

    def signin(n \\ nil, delay \\ nil) do
        
        users = Cache.select_by_attribute(:user_cache, :role, "subject")
        # get users without a status
        users = Enum.filter users, fn user -> user.status == nil end

        users = if n == nil do
            Enum.shuffle users
        else
            Enum.take_random users, n
        end

        Enum.with_index(users) |> Enum.each(fn { user, _i } ->

            if delay != nil do
                :timer.sleep(delay)
            end

            # # controled ideology
            # ideology = if i < 450 do
            #     "1"
            # else
            #     "7"
            # end

            # Random ideology
            ideology = "#{ Enum.random([1, 7]) }"

            user_record = Accounts.update_account_data(user, %{ 
                "alleged_ideology" => ideology,
                "current_ideology" => ideology,
                "agreed_to_terms" => true, 
                "agreed_to_personal_data" => true,
                "status" => "signed in" 
            })

            NetworkAssistant.add_user(user_record) 
        end)

        :ok
    end

    def message_decisions() do
        #  create messages for non-control users
        for user <- Cache.select_by_attribute(:user_cache, :condition_1, "random") do
            messages = Messages.generate_control_messages_for_user(user, 30)
            for message <- messages do
                Messages.insert(message)
            end
        end
        for user <- Cache.select_by_attribute(:user_cache, :condition_1, "homophilous") do
            messages = Messages.generate_control_messages_for_user(user, 30)
            for message <- messages do
                Messages.insert(message)
            end
        end
        messages = Cache.list_values(:message_cache)
        for message <- messages do
            Messages.update(message, %{ decision: "share" })
        end
        :ok
    end


    def attach_messages_to_user_id(id, n \\ 20) do
        user = Accounts.get_user(id)
        messages = Messages.generate_control_messages_for_user(user, n)
        Enum.each messages, fn m -> Messages.insert(m) end
    end


    def sim_player(id) do
        user = Accounts.get_user(id)
        attach_messages_to_user_id(id, 30)
        messages = Messages.list_receiver_messages(user)
        for m <- messages do
            :timer.sleep(5_000)
            # share this messages
            um = Messages.update(m, %{ "decision" => "share" })
            # and set it off to message_sharer
            NetworkLab.GenServers.MessageSharer.share(user, um)
        end
    end


    def sim_almost_all_players(without \\ []) do
        real_players = MapSet.new(Enum.map(without, fn id -> Accounts.get_user(id) end))
        users = Cache.select_by_attribute(:user_cache, :role, "subject")
        all_users = MapSet.new(Enum.filter(users, fn u -> u.status == "signed in" || u.status == "playing" end))
        ghosts = MapSet.difference(all_users, real_players)

        Enum.each 1..24, fn _ ->

            # get all undecided messages
            undecided_messages = Cache.select_by_attribute(:message_cache, :decision, nil)

            # get per ghost the oldest undecided message
            messages = Enum.map ghosts, fn user ->
                # get per user all his/her undecided messages
                ghost_messages = Enum.filter(undecided_messages, fn m -> m.receiver_id == user.id end)
                # order by inserted_at and take the oldest one, if the ghost has any
                if length(ghost_messages) > 0 do
                    [message | _] = if Application.get_env(:network_lab, :game_type) == :pretest do
                        Enum.sort_by(ghost_messages, & &1.position)
                    else
                        Enum.sort(ghost_messages, &(NaiveDateTime.compare(&1.inserted_at, &2.inserted_at)==:lt))
                    end
                    # return the message
                    message
                else
                    nil
                end
            end

            # remove the nil's
            messages = Enum.filter(messages, & !is_nil(&1))

            for message <- messages do

                # user
                user = Cache.get(:user_cache, message.receiver_id)

                # get proposition
                prop = Propositions.get_proposition(message.proposition_id)

                # is it false?
                decision = case { user.ideology, prop.post_intended_as_liberal, prop.post_is_false } do
                    # aligned but false
                    { "liberal", true, true } -> get_choice([share: 0.55, discard: 0.45], :rand.uniform)
                    # aligned and true
                    { "liberal", true, false } -> get_choice([share: 0.75, discard: 0.25], :rand.uniform)
                    # not aligned and false
                    { "liberal", false, true } -> get_choice([share: 0.4, discard: 0.6], :rand.uniform)
                    # not aligned but true
                    { "liberal", false, false } -> get_choice([share: 0.6, discard: 0.4], :rand.uniform)
        
                    # not aligned and false
                    { "conservative", true, true } -> get_choice([share: 0.4, discard: 0.6], :rand.uniform)
                    # not aligned but true
                    { "conservative", true, false } -> get_choice([share: 0.6, discard: 0.4], :rand.uniform)
                    # aligned but false
                    { "conservative", false, true } -> get_choice([share: 0.55, discard: 0.45], :rand.uniform)
                    # aligned and true
                    { "conservative", false, false } -> get_choice([share: 0.75, discard: 0.25], :rand.uniform)
                end

                decision = Atom.to_string(decision)

                # decision = case { user.ideology, prop.post_intended_as_liberal } do
                #     { "liberal", true } -> "share"
                #     { "liberal", false } -> "discard"
                #     { "conservative", false } -> "share"
                #     { "conservative", true } -> "discard"
                # end

                updated_message = Messages.update(message, %{ "decision" => decision })
                

                if Application.get_env(:network_lab, :game_type) != :pretest and 
                    decision == "share" && user.condition_1 != "control" do

                    NetworkLab.GenServers.MessageSharer.share(user, updated_message)
                end

            end
            # :timer.sleep(10_000)
            :timer.sleep(2_100)
        end
    end

    defp get_choice([{glyph,_}], _), do: glyph
    defp get_choice([{glyph,prob}|_], ran) when ran < prob, do: glyph
    defp get_choice([{_,prob}|t], ran), do: get_choice(t, ran - prob)

    #recompile(); NetworkLab.Simulator.sim_almost_all_players([1807])
    #recompile() ; NetworkLab.Simulator.signin(450)

    # mix ecto.rollback --all ; mix ecto.migrate ; mix run priv/repo/seeds.exs
    # NetworkLab.Simulator.signin(190)
    # NetworkLab.Simulator.sim_almost_all_players([])

    #recompile() ; NetworkLab.Simulator.test_db_assistant()
    #a = NetworkLab.GenServers.DatabaseAssistant.list()


    def test_db_assistant() do
        NetworkAssistant.drop_queues()
        DBA.flush()
        signin()
        message_decisions()
    end


    def print_networks() do
        for network <- Networks.list_networks() do
            if network.condition_1 != "control" do
                nodes = Enum.sort(Map.keys(network.node_mapping)) |> Enum.chunk_every(6)
                for row <- nodes do
                    res = Enum.map row, fn node_id ->
                        user_id = network.node_mapping[node_id]
                        user = Accounts.get_user(user_id)
                        String.at(user.ideology, 0)

                    end
                    IO.inspect(res, charlists: :as_lists)
                end
            end
            IO.inspect(nil)
        end
        :ok
    end

end