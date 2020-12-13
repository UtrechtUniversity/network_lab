defmodule NetworkLabWeb.UserChannel do
    use Phoenix.Channel

    alias NetworkLab.Accounts

    require Logger

    def join("user:" <> id, _payload, socket) do
        {:ok, assign(socket, :user_id, String.to_integer(id))} 
    end

    def handle_in(event, payload, socket = %{ user_id: user_id }) do
        user = 
            case user_id do
                x when is_integer(x) -> Accounts.get_user(user_id)
                _ -> nil
            end
        handle_in(event, payload, user, socket)
    end

    # only allow "ping" to be processed
    def handle_in("message", payload, user, socket) do
        broadcast(socket, "response", %{body: "test", user: user})
        {:reply, {:ok, payload}, socket}
    end



end