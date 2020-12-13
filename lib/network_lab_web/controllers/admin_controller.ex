defmodule NetworkLabWeb.AdminController do

  use NetworkLabWeb, :controller

  alias NetworkLab.Accounts
  alias NetworkLab.Networks
  alias NetworkLab.GenServers.Exporter

  plug :logged_in_user # when action not in [:new, :create]
  plug :admin_user


  def index(conn, _params) do
    users = Accounts.list_subjects()
    networks = Networks.list_networks()
    render(conn, :index, %{ networks: networks, users: users })
  end


  def export(conn, _params) do
    task = Task.async(fn ->
      timestamp = NaiveDateTime.to_string(NaiveDateTime.truncate(NaiveDateTime.utc_now(),:second))
      file_name = "export_" <> String.replace(timestamp, ~r"\s+", "_")
      Exporter.create_export_file(file_name)
    end)

    path = Task.await(task, :infinity)

    case File.exists?(path) do
      false ->
        conn
        |> put_flash(:error, "Could not find export file!")
        |> redirect(to: "/admin")
      true ->
        file = File.read!(path)
        conn
        |> put_resp_content_type("application/x-zip-compressed")
        |> put_resp_header("content-disposition", "attachment; filename=\"#{ Path.basename(path )}\"")
        |> send_resp(200, file)
    end
  end


  def flush_queue(conn, _params) do
    NetworkLab.GenServers.NetworkAssistant.flush_queues_to_control()
    redirect(conn, to: "/admin")
  end


  def tokens(conn, _params) do
    users = Accounts.list_subjects()
    render(conn, :tokens, %{ users: users })
  end

end

  