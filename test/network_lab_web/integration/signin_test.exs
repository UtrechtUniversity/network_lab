defmodule NetworkLabWeb.SigninTest do
    use NetworkLabWeb.IntegrationCase, async: false

    # https://littlelines.com/blog/2017/11/06/exunit-quick-reference#setupexit

    alias NetworkLab.SeedHelper
    alias NetworkLab.Accounts

    # import Wallaby.Query, only: [css: 2]
    # import Wallaby.Browser

    # This particular test 
    setup_all do

        SeedHelper.clear()
        SeedHelper.create_admin()
        SeedHelper.create_n_subjects(50)
        SeedHelper.create_networks([
            { :network_1, :homophilous, 98 },
            { :network_2, :control, nil }
        ])
        IO.puts "Done with seeding"

        # Crash my supervisor to ensure reloading of Database data in Cache
        IO.puts "Stop supervisor"
        Supervisor.stop(:genserver_supervisor, :shutdown)

        # This ensures that all is running again after crashing te supervisor
        { :ok, _ } = Application.ensure_all_started(:network_lab)

        # This seems necessary for async: False tests
        :timer.sleep(3000)

        on_exit fn ->
            IO.puts "Done with test"
        end
    end

    test "signin first liberal", %{ session: session } do

        # pick a user
        user = Enum.random(Cache.select_by_attribute(:user_cache, :ideology, "liberal"))

        # check queue
        %{ liberal: libs_old, conservative: cons_old } = NetworkLab.GenServers.NetworkAssistant.get_queues()

        # visit welcome and click on Go
        session = 
            session
            |> visit("/welcome?access_token=#{ user.access_token }")
            |> click(Query.checkbox("terms_of_service"))

        assert has_text?(session, "you self-identified as a liberal") == true

        session
        |> click(Query.button("go"))

        # refresh user
        user = Accounts.get_user(user.id)

        # assert ideology and agreement
        assert user.ideology == "liberal"
        assert user.agreed_to_terms == true

        # check queue
        %{ liberal: libs, conservative: cons } = NetworkLab.GenServers.NetworkAssistant.get_queues()

        assert length(cons) == length(cons_old)
        assert length(libs) == length(libs_old) + 1

        # assert user is member of correct queue
        assert Enum.member?(libs, user) == true
        assert Enum.member?(cons, user) == false

        # take_screenshot(session)
    end


    test "signin first conservative", %{ session: session } do

        # pick a user
        user = Enum.random(Cache.select_by_attribute(:user_cache, :ideology, "conservative"))

        # check queue
        %{ liberal: libs_old, conservative: cons_old } = NetworkLab.GenServers.NetworkAssistant.get_queues()

        # visit welcome and click on Go
        session =
            session
            |> visit("/welcome?access_token=#{ user.access_token }")
            |> click(Query.checkbox("terms_of_service"))

        assert has_text?(session, "you self-identified as a conservative") == true

        session
        |> click(Query.button("go"))

        # refresh user
        user = Accounts.get_user(user.id)

        # assert ideology and agreement
        assert user.ideology == "conservative"
        assert user.agreed_to_terms == true

        # check queue
        %{ liberal: libs, conservative: cons } = NetworkLab.GenServers.NetworkAssistant.get_queues()

        assert length(cons) == length(cons_old) + 1
        assert length(libs) == length(libs_old)

        # assert user is member of correct queue
        assert Enum.member?(cons, user) == true
        assert Enum.member?(libs, user) == false

        # take_screenshot(session)
    end

end