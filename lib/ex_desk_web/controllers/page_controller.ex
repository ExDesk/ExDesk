defmodule ExDeskWeb.PageController do
  use ExDeskWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
