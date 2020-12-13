defmodule NetworkLab.Accounts do

    alias NetworkLab.Repo
    alias NetworkLab.Accounts.User
    alias NetworkLab.GenServers.Cache
    alias NetworkLab.PretestWorkloads

    import Ecto.Changeset
    import Ecto.Query, only: [from: 2, order_by: 2]

    require Logger

    def get_user(id, store \\ :cache) do
        case store do
            :cache ->
                Cache.fetch(:user_cache, id, nil)
            :db ->
                Repo.get(User, id)
        end
    end


    def get_user!(id) do
        user = get_user(id, :cache)

        user = case user do
            %User{} -> user
            _ -> get_user(id, :db)
        end

        user
    end


    def get_user_by_access_token(token, store \\ :cache) do
        case store do
            :db ->
                Repo.get_by(User, access_token: token)
            :cache ->
                case Cache.select_by_attribute(:user_cache, :access_token, token) do
                    [] ->  { :not_found }
                    [ user ] -> user
                    [ _, _ | _] -> {:multiple_users_found}
            end
        end
    end


    def list_users(store \\ :cache) do
        case store do
            :db ->
                User
                |> order_by(asc: :id)
                |> Repo.all()
            :cache ->
                Cache.list_values(:user_cache)
        end
    end


    def list_subjects(store \\ :cache) do
        case store do
            :db ->
                Repo.all(from u in User, order_by: u.id, where: u.role == "subject")
            :cache ->
                Cache.select_by_attribute(:user_cache, :role, "subject")
        end
    end


    def get_neighbours(user) do
        if user.neighbour_ids == nil do
            []
        else
            Enum.map user.neighbour_ids, fn id ->
                get_user(id)
            end
        end
    end


    # This function is used in a form so we have to be careful and return a changeset
    # if things go wrong
    def update_account_data(%User{} = user, attrs \\ %{}) do
        # determine ideology
        { ideology, ideology_conflict } = determine_ideology(attrs)
        # update attrs
        attrs = Map.merge(attrs, %{
            "ideology" => ideology,
            "ideology_conflict" => ideology_conflict
        })
        # create changeset
        changeset = User.user_changeset(user, attrs)
        case changeset.valid? do
            false -> 
                # make sure the action is set so the form will pick up the errors for
                # the error tags
                %{changeset | action: :update}
            true ->
                updated_user = apply_changes(changeset)
                # store in cache
                NetworkLab.GenServers.Cache.set(:user_cache, user.id, updated_user)
                # store async in database
                NetworkLab.GenServers.DatabaseAssistant.add(
                    %{ action: "update", changeset: changeset }
                )
                # return updated user
                updated_user
        end
    end


    # determine ideology based on attributes of form data, this has to be made bomb-proof!
    defp determine_ideology(attrs) do
        alleged_ideology = "#{ attrs["alleged_ideology"] }"
        current_ideology = "#{ attrs["current_ideology"] }"

        ideologies = Application.get_env(:network_lab, :ideologies)

        { _, _, alleged_ideology } = Enum.find(ideologies, { :error, :error, "unknown" }, fn { id, _, _ } -> 
            id == alleged_ideology end)
        { _, _, current_ideology } = Enum.find(ideologies, { :error, :error, "unknown" }, fn { id, _, _ } -> 
            id == current_ideology end)

        if alleged_ideology != current_ideology do
            { current_ideology, true }
        else
            if current_ideology == "unknown" do
                # could not find alleged AND current ideology, return
                # ideology "moderate" and add an ideology conflict
                { "moderate", true }
            else
                { current_ideology, false }
            end
            
        end
    end


    def update_user_status(%User{} = user, status) do
        attrs = %{ status: status }
        changeset = User.user_status_changeset(user, attrs)
        updated_user = apply_changes(changeset)
        # cache
        NetworkLab.GenServers.Cache.set(:user_cache, user.id, updated_user)
        # db
        NetworkLab.GenServers.DatabaseAssistant.add(
            %{ action: "update", changeset: changeset }
        )
        # return updated user
        updated_user
    end


    # this is a system thing, I won't validate stuff
    def attach_user_to_network(%User{} = user, attrs \\ %{}) do
        # create changeset
        changeset = User.network_changeset(user, attrs)

        updated_user = apply_changes(changeset)
        # store in cache
        NetworkLab.GenServers.Cache.set(:user_cache, user.id, updated_user)
        # store async in database
        NetworkLab.GenServers.DatabaseAssistant.add(
            %{ action: "update", changeset: changeset }
        )
        # return updated user
        updated_user        
    end


    def authenticate_by_access_token(token) do
        user = get_user_by_access_token(token)
        case user do
            %User{} ->
                { :ok, user }
            _ ->
                { :error, :not_found }
        end
    end


    # not sure if this function is necessary: get the workload of subject (in pretest situation)
    def get_workload(user) do
        case user.ideology do
            "liberal" ->
                { :ok, PretestWorkloads.get_workload(user.workload["liberal"]) }
            "conservative" ->
                { :ok, PretestWorkloads.get_workload(user.workload["conservative"]) }
            "moderate"->
                { :ok, PretestWorkloads.get_workload(user.workload["moderate"]) }
            _ ->
                { :error, :no_ideology }
        end
    end

end