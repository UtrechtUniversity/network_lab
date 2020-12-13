defmodule NetworkLabWeb.TaskController do

    use NetworkLabWeb, :controller

    alias NetworkLab.Accounts
    alias NetworkLab.Messages
    alias NetworkLab.Messages.Message
    alias NetworkLab.Networks

    require Logger

    plug :logged_in_user # from NetworkLabWeb and NetworlLab.auth

    def action(conn, _) do
        apply(__MODULE__, action_name(conn), 
            [conn, conn.params, Accounts.get_user(conn.assigns.current_user_id)])
    end


    def index(conn, _params, current_user) do
        network = Networks.get_network(current_user.network_id)
        all_messages = Messages.list_receiver_messages(current_user)
        # split messages by decision
        { decided, undecided } = Enum.split_with(all_messages, fn m -> m.decision != nil end)

        # this is the non-javascript path towards exit: if there are no more undecided messages
        # and either we are in control, pretest or network_messaging is over -> move to exit
        if length(decided) > 0 and length(undecided) == 0 and (
                Application.get_env(:network_lab, :game_type) == :pretest or
                current_user.condition_1 == "control" or
                network.allow_messaging == false
            ) do

            # set user status to finish
            current_user = Accounts.update_user_status(current_user, "finished")
            # broadcast to admin
            NetworkLabWeb.Endpoint.broadcast("admin_channel", "update", %{ payload: [
                %{ selector: "#user-#{current_user.id} td.status", contents: current_user.status }
            ]})
            # redirect to exit
            redirect(conn, to: "/exit")
        else

            game_type = Application.get_env(:network_lab, :game_type)
            # sort on inserted at and decision_made_at
            { decided, undecided } = if game_type == :pretest or current_user.condition_1 == "control" do
                # sort on position if there is one
                un = Enum.sort_by undecided, & &1.position
                de = Enum.sort_by decided, & &1.position
                { de, un }
            else
                # # sort on insertion timestamp (last message comes on top)
                un = Enum.sort(undecided, &(NaiveDateTime.compare(&1.inserted_at, &2.inserted_at)==:lt))
                de = Enum.sort(decided, &(NaiveDateTime.compare(&1.inserted_at, &2.inserted_at)==:lt))
                { de, un }
            end

            # render
            render(conn, :index, %{ 
                undecided_messages: undecided, 
                decided_messages: decided,
                user: current_user, 
                network: network 
            })
        end
    end

    # make this bomb-proof: try to find it in cache, if I can't find it try to 
    # find it in the database, if that can't be found redirect, otherwise show page
    def edit(conn, %{ "id" => id }, current_user) do

        {id, ""} = Integer.parse(id)
        message = Messages.get_message!(id)

        # still not found, or found
        if message == nil do
            conn
            |> put_flash(:error, 
                "Sorry, the system couldn't find the message, please try again or try another message first.")
            |> redirect(to: "/task")
        else
            decision_changeset = Message.decision_changeset(message)
            render(conn, :edit, %{ changeset: decision_changeset, message: message, user: current_user })
        end

    end


    def update(conn, %{ "id" => id, "message" => decision}, current_user) do

        {id, ""} = Integer.parse(id)
        message = Messages.get_message!(id)

        if message == nil do
            conn
            |> put_flash(:error, 
                "Sorry, the system couldn't process your decision, please try again or try another message first.")
        else

            Messages.update(message, decision)

            # THIS WILL TRIGGER SHARING
            if Application.get_env(:network_lab, :game_type) != :pretest do
                if current_user.condition_1 != "control" && decision["decision"] == "share" do
                    NetworkLab.GenServers.MessageSharer.share(current_user, message)
                end
            end
        end

        redirect(conn, to: "/task")
    end


    def wait(conn, _params, current_user) do
        
        queue_status = if (current_user.network_id == nil) do
            %{ no_liberals: waiting_libs, no_conservatives: waiting_cons } = NetworkLab.GenServers.NetworkAssistant.queue_status()
            available_network = NetworkLab.Networks.available_network()

            if available_network.condition_1 == "control" do
                nil
            else
                NetworkLab.Networks.waiting_for_how_many_subjects(
                    available_network, 
                    waiting_libs, 
                    waiting_cons
                )
            end
        else
            nil
        end

        render(conn, :wait, %{ user: current_user, queue_status: queue_status })
    end

end