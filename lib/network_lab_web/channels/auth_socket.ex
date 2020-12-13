defmodule NetworkLabWeb.AuthSocket do
    use Phoenix.Socket

    alias NetworkLab.Accounts
    alias NetworkLab.Accounts.User

    require Logger

    channel "user:*", NetworkLabWeb.UserChannel
    channel "admin_channel", NetworkLabWeb.AdminChannel
    channel "waiting_channel", NetworkLabWeb.WaitingChannel

    @two_weeks 60 * 60 * 24 * 7 * 2

    def connect(%{ "token" => token }, socket, _connect_info) do
        case verify(socket, token) do
            { :ok, user_id } ->

                # get user out of the cache
                user = Accounts.get_user(user_id)
                case user do
                    %User{} ->
                        socket = 
                        socket
                        |> assign(:user_id, user_id)
                        |> assign(:role, user.role)
                        |> assign(:neighbour_ids, user.neighbour_ids)
                        { :ok, socket }
                    _ ->
                        Logger.error("#{__MODULE__} connect error: could not find user with id: #{user_id}")
                        :error
                end

            { :error, reason } ->
                Logger.error("#{__MODULE__} connect error #{inspect(reason)}")
                :error
        end
    end

    def connect(_, _socket) do
        Logger.error("#{__MODULE__} connect error missing params")
        :error
    end

    def id(_socket = %{assigns: %{user_id: user_id}}), do: "auth_socket:#{user_id}"

    defp verify(socket, token) do
        Phoenix.Token.verify( 
            socket,
            NetworkLabWeb.Endpoint.config(:secret_key_base),
            token, 
            max_age: @two_weeks
        )
    end
    
end
