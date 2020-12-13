defmodule NetworkLabWeb.NetworkAssignmentTest do
    use NetworkLabWeb.IntegrationCase, async: false

    alias NetworkLab.SeedHelper
    alias NetworkLab.Networks
    alias NetworkLab.Networks.Network

    import Wallaby.Query, only: [css: 2]
    import Wallaby.Browser

    # This particular test 
    setup do

        SeedHelper.clear()
        SeedHelper.create_admin()
        SeedHelper.create_n_subjects(500)
        SeedHelper.create_networks([
            {
                :network_1, 
                Enum.random([:homophilous, :random]),
                Enum.random([:flat_fee, :incentive]), 
                98
            },
            { :network_6, :control, nil }
        ])
        IO.puts "Done with seeding"

        # Crash my supervisor to ensure reloading of Database data in Cache
        IO.puts "Stop supervisor"
        Supervisor.stop(:genserver_supervisor, :shutdown)

        # This ensures that all is running again after crashing te supervisor
        { :ok, _ } = Application.ensure_all_started(:network_lab)
        :timer.sleep(3000)

        on_exit fn ->
            IO.puts "Done with test"
        end
    end

    test "assignment to network once enough libs and cons" , %{ session: session } do
        # check state of networks before subjects come in
        # fill networks
        # check if amount of attached users is correct
        # check if users are attached to network

        networks = Cache.list_values(:network_cache)
        assert length(networks) == 2
        [ non_control, %Network{ condition_1: "control" } = control ] = networks

        assert control.attached_users == 0
        assert control.started_at == nil

        assert non_control.attached_users == 0
        assert non_control.started_at == nil

        libs = Enum.take_random(Cache.select_by_attribute(:user_cache, :ideology, "liberal"), 100)
        cons = Enum.take_random(Cache.select_by_attribute(:user_cache, :ideology, "conservative"), 100)

        subjects = Enum.shuffle(libs ++ cons)

        Enum.each subjects, fn user ->
         # visit welcome and click on Go
            session
            |> visit("/welcome?access_token=#{ user.access_token }")
            |> click(Query.checkbox("terms_of_service"))
            |> click(Query.button("go"))
        end

        # there should be no one in the queue, because we have more than enough subjects to fill the 
        # non-control network
        %{ liberal: libs, conservative: cons } = NetworkLab.GenServers.NetworkAssistant.get_queues()
        assert length(libs) == 0
        assert length(cons) == 0

        # check the networks, starting with control:
        control_network = Networks.get_network(control.id)
        non_control_network = Networks.get_network(non_control.id)

        assert non_control_network.attached_users == non_control_network.capacity
        assert control_network.attached_users == (200 - non_control_network.attached_users)

        # check the user side of things
        control_users = Cache.select_by_attribute(:user_cache, :network_id, control_network.id)
        non_control_users = Cache.select_by_attribute(:user_cache, :network_id, non_control_network.id)

        assert (length(control_users)) == control_network.attached_users
        assert (length(non_control_users)) == non_control_network.attached_users

        # check started_at
        assert control_network.started_at != nil
        assert non_control_network.started_at != nil

    end



    #test "flushing when there are not enough people in the queue"

end