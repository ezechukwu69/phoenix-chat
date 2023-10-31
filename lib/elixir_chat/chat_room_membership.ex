defmodule ElixirChat.ChatRoomMembership do
  alias ElixirChat.ChatRoom
  alias ElixirChat.Accounts.User
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "chat_room_membership" do

    belongs_to :room, ChatRoom
    belongs_to :user, User, type: :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(chat_room_membership, attrs) do
    chat_room_membership
    |> cast(attrs, [:room_id, :user_id])
    |> validate_required([:room_id, :user_id])
  end
end
