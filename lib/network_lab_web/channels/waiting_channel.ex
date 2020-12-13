defmodule NetworkLabWeb.WaitingChannel do
    use Phoenix.Channel

    def join("waiting_channel", _payload, socket) do
        {:ok, socket} 
    end

end