defmodule ElixirChatWeb.ChatController do
  use ElixirChatWeb, :controller

  def index(conn, _params) do
    put_session(conn, :current_user, conn.assigns.current_user)
    render(conn, :index, %{"current_user" => conn.assigns.current_user})
  end
end
