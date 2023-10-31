defmodule ElixirChatWeb.ChatLive do
  alias Phoenix.Endpoint
  alias ElixirChat.Repo
  alias ElixirChat.ChatMessage
  alias ElixirChat.NewMessage
  alias Phoenix.Socket.Broadcast
  alias ElixirChat.Accounts
  alias ElixirChatWeb.Endpoint
  import Ecto.Query
  use ElixirChatWeb, :live_view

  @topic "chat"

  def mount(_params, %{"user_token" => user_token} = _session, socket) do
    user = Accounts.get_user_by_session_token(user_token)
    socket =
      assign_new(socket, :current_user, fn ->
        user
      end)
    if connected?(socket) do
      Endpoint.subscribe("room:#{user.id}")
    end
    socket = assign(socket, :chat_id, nil)
      |> assign(:current_user, user.id)
   {:ok, socket, layout: false}
  end

  def render(assigns) do
    ~H"""
      <div class="border border-grey-200 rounded-lg p-4 min-h-[70vh] max-h-[70vh] flex flex-col">
        <%= if is_nil(@chat_id) do %>
          <div class="flex-1 w-full h-full flex items-center justify-center">
            <h1 class="text-lg font-semibold">Select a Chat</h1>
          </div>
        <% else %>
          <div class="flex-1 flex flex-col-reverse overflow-y-scroll scrollbar-none" phx-update="stream" id={@chat_id}>
            <%= for {message_id, message} <- @streams.messages do %>
              <div class={"my-1 #{if message.sender_id != @current_user, do: "flex justify-start", else: "flex justify-end"}"} id={message_id}>
               <div>
                 <%= # <p class="text-xs">@<%= message.sender.email %>
                 <p class={"p-3 rounded-lg max-w-min #{if message.sender_id != @current_user, do: "bg-blue-600 text-white", else: "bg-green-500 text-white"}"}><%= message.text %></p>
               </div>
              </div>
            <% end %>
          </div>
          <.form for={@new_message} phx-submit="send_message" class="flex w-full space-x-3 items-end">
            <div class="w-full h-full">
              <.input type="text" field={@new_message[:text]}/>
            </div>
            <.button class="h-[42px]"><Heroicons.Solid.paper_airplane class="h-3 w-6 text-blue-500"/></.button>
          </.form>
        <% end %>
      </div>
    """
  end

  def handle_event("send_message", %{"new_message" => new_message} = _message, socket) do
    message = Map.put(new_message, "sender_id", socket.assigns.current_user)
    message = Map.put(message, "chat_room_id", socket.assigns.chat_id)
    changeset = ChatMessage.changeset(%ChatMessage{}, message)
    socket = case Repo.insert(changeset) do
      {:ok, message} ->
         newMessage = NewMessage.changeset(%{})
         socket = assign(socket, :new_message, newMessage |> to_form())
         stream_insert(socket, :messages, message, at: 0)
      {:error, _changeset} -> 
          newMessage = NewMessage.changeset(%{text: message["text"]})
          assign(socket, :new_message, newMessage |> to_form(as: "new_message"))
    end
    Endpoint.broadcast_from(self(), "chat_room:#{socket.assigns.chat_id}", "new_message", %{message: message})
    {:noreply, socket}
  end


  def handle_info(%Broadcast{topic: "chat_room:"<>_room_id, event: "new_message", payload: payload}, socket) do
    query = from c in ChatMessage, where: c.chat_room_id == ^socket.assigns.chat_id, join: r in assoc(c, :chat_room), join: u in assoc(c, :sender), order_by: [asc: :inserted_at], preload: :sender
    socket = stream(socket, :messages, Repo.all(query), at: 0)
    {:noreply, socket}
  end

  def handle_info(%Broadcast{topic: "room:"<>user_id, event: "join_room", payload: payload}, socket) do
    IO.inspect(user_id)
    if user_id == socket.assigns.current_user do
      {:noreply, socket}
    else
      %{room_id: room_id} = payload
      newMessage = NewMessage.changeset(%{})
      query = from c in ChatMessage, where: c.chat_room_id == ^room_id, join: r in assoc(c, :chat_room), join: u in assoc(c, :sender), order_by: [desc: :inserted_at], preload: :sender
      socket = assign(socket, :chat_id, room_id)
      Endpoint.subscribe("chat_room:#{room_id}")
      socket = assign(socket, :new_message, newMessage |> to_form())
      socket = stream(socket, :messages, Repo.all(query))
      {:noreply, socket}
    end
  end
end
