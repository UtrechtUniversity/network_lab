defmodule NetworkLab.Auth do
    
    import Plug.Conn
    import Phoenix.Controller

    require Logger

    # init
    def init(opts), do: opts

    # 
    def call(conn, _opts) do
        user_id = get_session(conn, :current_user_id)
        user = user_id && NetworkLab.Accounts.get_user(user_id)
        # is this an admin or a participant
        put_current_user(conn, user)
    end

    # if you -are- logged in, this function just passes the conn
    def logged_in_user(conn = %{assigns: %{ current_user_id: _}}, _), do: conn

    # if you are -not- logged in, this function will redirect you
    def logged_in_user(conn, _opts) do
        conn
        |> put_flash(:error, "You must be logged in to access the requested page")
        |> redirect(to: "/subject_removed")
        |> halt()
    end

    def logged_in?(%{assigns: assigns} = _conn) do
        Map.has_key?(assigns, :current_user_id) && is_integer(Map.get(assigns, :current_user_id))
    end

    # if you -are- an admin user, this function just passes the conn
    def admin_user(conn = %{assigns: %{ admin_user: true }}, _), do: conn

    # if you are -not- an admin user, this function will redirect you 
    def admin_user(conn, _opts) do
        conn
        |> put_flash(:error, "You must be an admin to access the requested page")
        |> redirect(to: "/subject_removed")
        |> halt()
    end

    def is_admin?(%{assigns: assigns} = conn) do
        logged_in?(conn) && Map.has_key?(assigns, :admin_user) && Map.get(assigns, :admin_user, false)
   end

    # set current_user, and admin_user
    defp put_current_user(conn, user) do
        # returns false if user does not exist
        token = user && Phoenix.Token.sign(
            conn, 
            NetworkLabWeb.Endpoint.config(:secret_key_base), 
            user.id)
        conn = conn 
        |> assign(:current_user_id, (if user, do: user.id, else: false))
        |> assign(:network_id, (if user && user.network_id != nil, do: user.network_id, else: false))
        |> assign(:admin_user, !!user && user.role == "admin")
        |> assign(:user_token, token)
        conn
    end


end