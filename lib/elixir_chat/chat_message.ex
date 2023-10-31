defmodule ElixirChat.ChatMessage do
  alias ElixirChat.Accounts.User
  alias ElixirChat.ChatRoom
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "chat_messages" do
    field :text, :string
    belongs_to :sender, User, type: :integer
    belongs_to :chat_room, ChatRoom

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(chat_message, attrs) do
    chat_message
    |> cast(attrs, [:text, :sender_id, :chat_room_id])
    |> validate_required([:text, :sender_id, :chat_room_id])
  end
end
