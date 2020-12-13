defmodule NetworkLab.Messages do

    alias NetworkLab.Repo
    alias NetworkLab.Propositions
    alias NetworkLab.Messages.Message
    alias NetworkLab.Accounts.User
    alias NetworkLab.Accounts
    alias NetworkLab.GenServers.Cache
    alias NetworkLab.GenServers.DatabaseAssistant
    
    
    import Ecto.Changeset
    import Ecto.Query, only: [from: 2]

    require Logger

    # inserting is always done by the system, so I wont go for changesets
    def insert(message) do
        # create a unique id number from receiver_id and proposition_id
        rid = message.receiver_id
        pid = message.proposition_id
        {key, ""} = Integer.parse("#{rid}0#{pid}")
        # time for created_at and updated_at
        now = NaiveDateTime.truncate(NaiveDateTime.utc_now(),:second)
        # add id to message struct
        message = %{ message | id: key, inserted_at: now,  updated_at: now }

        # create changeset
        changeset = Message.insert_changeset(message)

        # store in cache
        Cache.set(:message_cache, key, message)
        # store async in database
        DatabaseAssistant.add(
            %{ action: "insert", changeset: changeset }
        )
        # return inserted message
        message
    end


    def update(message, attrs \\ %{}) do
        # create changeset
        changeset = Message.decision_changeset(message, attrs)

        case changeset.valid? do
            false -> 
                changeset
            true ->
                updated_message = apply_changes(changeset)
                # store in cache
                NetworkLab.GenServers.Cache.set(
                    :message_cache,
                    message.id,
                    updated_message
                )
                # store async in database
                DatabaseAssistant.add(
                    %{ action: "update", changeset: changeset }
                )
                # return updated message
                updated_message
        end
    end


    def list_receiver_messages(%User{ id: receiver_id }, store \\ :cache) do
        case store do
            :cache ->
                Cache.select_by_attribute(:message_cache, :receiver_id, receiver_id)
            :db ->
                query = from m in Message, where: m.receiver_id == ^receiver_id, order_by: m.updated_at
                Repo.all(query)
        end
    end


    def get_message_by_receiver_and_proposition(user, proposition_id, store \\ :cache) do
        # is this an id, or is it a User struct? return user id
        receiver_id = case user do
            %User{ id: receiver_id } -> receiver_id
            user -> user
        end
        case store do
            :cache ->
                messages = Cache.get(:message_cache, receiver_id)
                Enum.find(messages, fn m -> m.proposition_id == proposition_id end)
            :db ->
                Repo.get_by!(Message, receiver_id: receiver_id, proposition_id: proposition_id)
        end
    end


    def list_messages(store \\ :cache) do
        case store do
            :cache ->
                Cache.list_values(:message_cache)
            :db ->
                Repo.all(Message)
        end
    end


    def get_message(id, store \\ :cache) do
        case store do
            :cache ->
                Cache.get(:message_cache, id)
            :db ->
                Repo.get(Message, id)
        end
    end


    def get_message!(id) do
        message = get_message(id, :cache)

        # did not find it in cache, find it in db
        message = case message do
            %Message{} -> message
            _ -> get_message(id, :db)
        end

        message
    end


    def get_message_by_user(%User{ id: receiver_id }, message_id) do
        Repo.get_by!(Message, id: message_id, receiver_id: receiver_id)
    end


    def user_has_messages?(%User{ id: receiver_id }) do
        query = from m in Message, where: m.receiver_id == ^receiver_id
        Repo.aggregate(query, :count, :id) > 0
    end


    # This generates messages for a user when there are none
    def generate_control_messages_for_user(user, n) do
        selected_propositions = Enum.take_random(Propositions.list_propositions(), n)
        Enum.map Enum.with_index(selected_propositions), fn { prop, index } ->
            create_message_for_user(
                user: user, 
                proposition: prop, 
                version: :show_version, 
                position: index
            )
        end
    end


    # Generate pretest messages for user
    def prepare_pretest_messages_for_user(user) do
        { :ok, [_, workload] } = Accounts.get_workload(user)
        Enum.map Enum.with_index(workload), fn { { id, _, version }, position } ->
            prop = Propositions.get_proposition(id)
            create_message_for_user(
                user: user, 
                proposition: prop, 
                version: version, 
                position: position
            )
        end
    end


    # This create a single message for a certain user
    def create_message_for_user(options) do

        # convert options into map
        options = Enum.into(options, %{})
        %{ user: user, proposition: prop, version: version } = options

        position = Map.get(options, :position)
        position = case position == nil do
            true -> 0
            false -> position
        end

        sender = Map.get(options, :sender) 
        sender_id = case sender == nil do
            true -> nil
            false -> sender.id
        end

        decision = Map.get(options, :decision)
        decision_made_at = case decision == nil do
            true -> nil 
            false -> NaiveDateTime.truncate(NaiveDateTime.utc_now(),:second)
        end

        # post_is_false == 1 -> take false post 
        # post_is_false == 0 -> take true post 
        use_version = if version != nil do
            case version do
                true -> "true"
                false -> "false"
                :show_version -> prop.show_version
            end
        else
            case prop.post_is_false do
                true -> "false"
                false -> "true"
            end
        end 

        %Message{
            network_id: user.network_id,
            sender_id: sender_id,
            receiver_id: user.id,
            proposition_id: prop.id,
            proposition_type: use_version,
            proposition_title: prop.title,
            proposition: Map.get(prop, String.to_existing_atom(use_version)),
            position: position,
            decision: decision,
            decision_made_at: decision_made_at
        }
    end


    def register_decision(%Message{} = message, attrs) do
        message
        |> Message.decision_changeset(attrs)
        |> Repo.update()
    end

end