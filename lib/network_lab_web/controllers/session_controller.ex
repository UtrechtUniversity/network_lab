defmodule NetworkLabWeb.SessionController do

    use NetworkLabWeb, :controller

    alias NetworkLab.Accounts
    alias NetworkLab.Accounts.User

    require Logger

    def new(conn, params) do

        %{ "access_token" => access_token, "g" => alleged_ideology } = params
        Logger.error("USER KNOCKED AT THE DOOR: #{ inspect(params) }")

        # look for the user
        user = Accounts.get_user_by_access_token(access_token)
        # if it is a user, I don't want him here unless he is new, make sure he/she is logged in
        case user do
            %User{} ->
                cond do
                    Enum.member?(["finished", "dropped"], user.status) ->
                        login_successful(user, conn, "/exit")
                    user.status == "playing" ->
                        login_successful(user, conn, "/task")
                    user.status == "signed_in" and user.network_id == nil ->
                        login_successful(user, conn, "/wait")
                    user.status == nil ->
                        user_changeset = User.user_changeset(user)
                        render(conn, :new, %{ 
                            user: user,
                            user_changeset: user_changeset,
                            alleged_ideology: alleged_ideology
                        })
                end
            _ ->
                conn
                |> put_flash(:error, "The provided access token #{access_token} is not associated with a user account")
                |> redirect(to: "/subject_removed")
        end
    end


    def create(conn, %{ "user" => params }) do
        %{ "access_token" => access_token } = params
        case Accounts.authenticate_by_access_token(access_token) do
            { :ok, user } ->
                Logger.error("USER GOT THROUGH: #{ inspect(params) }")
                case user.role do
                    "admin" ->
                        login_successful(user, conn, "/admin")
                    "subject" ->
                        # inject user status
                        params = Map.put(params, "status", "signed_in")

                        # Bad access_token, -> back -> good access token, no ideology, -> gets to task
                        updated_user = Accounts.update_account_data(user, params)

                        case updated_user do

                            %Ecto.Changeset{} ->
                                conn
                                |> put_flash(:error, "Please agree to our terms of service and select your political preference.")
                                |> render(:new, %{ 
                                    user: user, 
                                    user_changeset: updated_user,
                                    alleged_ideology: params["alleged_ideology"]
                                })

                            _ ->
                                # admin wants to know this
                                NetworkLabWeb.Endpoint.broadcast("admin_channel", "update", %{ payload: [
                                    %{ selector: "#user-#{updated_user.id} td.status", contents: updated_user.status }
                                ]})

                                # Things are OK, we start a session, assign to network
                                NetworkLab.GenServers.NetworkAssistant.add_user(updated_user)
                                login_successful(updated_user, conn, "/wait")
                        end
                end

            { :error, :not_found} ->
                Logger.error("USER FAILED TO GO THROUGH: #{ inspect(params) }")
                conn
                |> put_flash(:error, "The provided access token #{access_token} is not associated with a user account")
                |> redirect(to: "/subject_removed")
        end
    end


    def delete(conn, _) do
        conn
        |> configure_session(drop: true)
        |> put_flash(:info, "Logged out")
        |> redirect(to: "/subject_removed")
    end


    defp login_successful(user, conn, route) do
        # conn
        conn
        |> put_flash(:info, "Successfully logged in. Please stay on this screen and read the (forthcoming) instructions.")
        |> put_session(:current_user_id, user.id)
        |> configure_session(renew: true)
        |> redirect(to: route)
    end

end