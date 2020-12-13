defmodule NetworkLabWeb.PageController do
  
  use NetworkLabWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end

end
