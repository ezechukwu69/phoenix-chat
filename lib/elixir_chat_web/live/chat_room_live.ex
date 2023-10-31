defmodule ElixirChatWeb.ChatRoomLive do
  alias Phoenix.Endpoint
  alias Phoenix.Endpoint
  alias ElixirChatWeb.Endpoint
  alias Phoenix.Socket.Broadcast
  alias ElixirChat.ChatRoomMembership
  alias ElixirChat.Accounts
  alias ElixirChat.Repo
  alias ElixirChat.ChatRoom
  import Ecto.Query
  use ElixirChatWeb, :live_view

  def mount(_params, %{"user_token" => user_token} = _session, socket) do
    socket =
      assign_new(socket, :current_user, fn ->
        Accounts.get_user_by_session_token(user_token)
      end)
    if connected?(socket) do
      Endpoint.subscribe("chat_room:#{socket.assigns.current_user.id}")
    end
    new_room = new_room()
    socket = assign(socket, :new_room, new_room)
    socket = assign(socket, :join_room, new_room)
    room_query = from u in ChatRoomMembership, where: u.user_id == ^socket.assigns.current_user.id, join: r in assoc(u, :room), select: r 
    rooms = Repo.all(room_query)
    socket = stream(socket, :rooms, rooms)
    {:ok, socket, layout: false}
  end

  defp new_room do
    ChatRoom.changeset(%ChatRoom{}, %{})
      |> to_form()
  end

  def render(assigns) do
    ~H"""
     <div class="w-full rounded-lg border border-grey-200 p-4">
        <.modal id="add" class="space-y-5">
          <.form for={@new_room} phx-submit="create" class="p-4 border rounded-md">
            <h1 class="text-lg font-bold mb-4">Create a Room</h1>
            <.label for="name">Room Name</.label>
            <.input field={@new_room[:name]} id="name" type="text" placeholder="Room name" required/>
            <.button class="mt-3" type="submit">Submit</.button>
          </.form>
          <.form for={@join_room} phx-submit="join" class="mt-5 p-4 border rounded-md">
            <h1 class="text-lg font-bold mb-4">Join a Room</h1>
            <.label for="name">Room ID</.label>
            <.input field={@new_room[:name]} id="name" type="text" placeholder="Room ID" required/>
            <.button class="mt-3" type="submit">Submit</.button>
          </.form>
        </.modal>
        <div class="flex justify-between">
          <h1 class="text-lg font-bold">Chat Rooms</h1>
          <button phx-click={show_modal("add")}>
            <Heroicons.Solid.plus_circle class="h-6 w-6 text-blue-500"/>
          </button>
        </div>
        <div phx-update="stream" id="rooms" class="mt-5">
          <ul>
           <%= for {room_id, room} <- @streams.rooms do %>
            <li  class="my-2" id={room_id}>
              <button class="text-lg text-blue-500 font-semibold" phx-click="join_room" phx-value-id={room.id}><%= room.name %></button>
            </li>
           <% end %>
          </ul>
        </div>
     </div>
    """
  end


  def handle_event("create", %{"chat_room" => chat_room}, socket) do
   chat_room = Map.put(chat_room, "owner_id", socket.assigns.current_user.id)
   room = ChatRoom.changeset(%ChatRoom{}, chat_room)

   socket = case Repo.insert(room) do
     {:ok, room} -> 
       create_membership(socket.assigns.current_user.id, room.id, socket)
     {:error, changeset} -> assign(socket, :new_room, changeset |> to_form())
   end
   Endpoint.broadcast("chat_room:#{socket.assigns.current_user.id}","new_room", %{})
   {:noreply, socket}
  end

  def handle_event("join", %{"chat_room" => chat_room}, socket) do
    IO.inspect(chat_room)
   room_query = from u in ChatRoomMembership, where: u.user_id == ^socket.assigns.current_user.id and u.room_id == ^chat_room["name"], join: r in assoc(u, :room), select: r 
   rooms = Repo.all(room_query)
   if Enum.empty?(rooms) do
     socket = create_membership(socket.assigns.current_user.id, chat_room["name"], socket)
     Endpoint.broadcast("chat_room:#{socket.assigns.current_user.id}","new_room", %{})
   end
   {:noreply, socket}
  end


  def handle_event("join_room", %{"id" => room_id}, socket) do
    IO.inspect(room_id)
    Endpoint.broadcast("room:#{socket.assigns.current_user.id}","join_room", %{room_id: room_id})
    {:noreply, socket}
  end


  def handle_info(%Broadcast{topic: "chat_room:"<>_user_id, event: "new_room", payload: _payload}, socket) do
    room_query = from u in ChatRoomMembership, where: u.user_id == ^socket.assigns.current_user.id, join: r in assoc(u, :room), select: r 
    rooms = Repo.all(room_query)
    socket = stream(socket, :rooms, rooms)
    {:noreply, socket}
  end


  defp create_membership(user_id, room_id, socket) do
    channel_membership = ChatRoomMembership.changeset(%ChatRoomMembership{}, %{"room_id" => room_id, "user_id" => user_id})
    case Repo.insert(channel_membership) do
      {:ok, _channel_membership} ->
        assign(socket, :new_room, new_room())
        put_flash(socket, :success, "Room created")
      {:error, changeset} -> 
        IO.inspect(changeset) 
        assign(socket, :new_room, changeset |> to_form())
    end
  end

end
