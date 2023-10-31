defmodule ElixirChat.Repo.Migrations.CreateChatRoomMembership do
  use Ecto.Migration

  def change do
    create table(:chat_room_membership, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :room_id, references(:chat_rooms, on_delete: :nothing, type: :binary_id)
      add :user_id, references(:users, on_delete: :nothing, type: :integer)

      timestamps(type: :utc_datetime)
    end

    create index(:chat_room_membership, [:room_id])
    create index(:chat_room_membership, [:user_id])
  end
end
