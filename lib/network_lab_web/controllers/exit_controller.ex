defmodule NetworkLabWeb.ExitController do
  
    use NetworkLabWeb, :controller

    alias NetworkLab.Accounts

    require Logger

    plug :logged_in_user when action in [:index] # from NetworkLabWeb and NetworkLab.Auth
    plug :redirect_unfinished when action in [:index] #-> plug to redirect to task if not finished


    def index(conn, _params) do
        user = Accounts.get_user(conn.assigns.current_user_id)
        render(conn, :index, %{ user: user })
    end


    def removed(conn, _params) do
        render(conn, :removed)
    end


    defp redirect_unfinished(conn, _params) do
        # get the user
        current_user = Accounts.get_user(conn.assigns.current_user_id)

        # redirect to task dynamically if the task has been finished
        if Enum.member?(["finished", "dropped"], current_user.status) == false do
            conn
            |> redirect(to: "/task")
            |> halt
        else
            conn
        end
    end
  
end