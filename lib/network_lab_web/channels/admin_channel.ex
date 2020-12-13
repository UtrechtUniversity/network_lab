defmodule NetworkLabWeb.AdminChannel do
    use Phoenix.Channel

    require Logger

    def join("admin_channel", _payload, socket) do
        {:ok, socket} 
    end

    # def handle_in(event, payload, socket = %{ user_id: user_id }) do
    #     IO.puts("&&&&&&& #{inspect(user_id)}")
    #     user = 
    #         case user_id do
    #             x when is_integer(x) -> Accounts.get_user(user_id)
    #             _ -> nil
    #         end
    #     IO.puts("&&&&&&& #{inspect(user)}")
    #     handle_in(event, payload, user, socket)
    # end

    # # only allow "ping" to be processed
    # def handle_in("message", payload, user, socket) do
    #     Logger.info("RECEIVED A MESSAGE")
    #     broadcast socket, "response", %{body: "fuckoff", user: user}
    #     {:reply, {:ok, payload}, socket}
    #     # payload must be a map
    #     # {:reply, {:ok, %{ping: "pong"}}, socket}
    # end

end