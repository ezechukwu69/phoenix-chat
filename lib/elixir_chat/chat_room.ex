defmodule ElixirChat.ChatRoom do
  alias ElixirChat.ChatRoom
  alias ElixirChat.Accounts.User
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "chat_rooms" do
    field :name, :string
    belongs_to :owner, User, type: :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(chat_room, attrs) do
    chat_room
    |> cast(attrs, [:name, :owner_id])
    |> validate_required([:name])
  end
end
