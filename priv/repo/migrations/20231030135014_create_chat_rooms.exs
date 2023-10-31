defmodule ElixirChat.Repo.Migrations.CreateChatRooms do
  use Ecto.Migration

  def change do
    create table(:chat_rooms, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :owner_id, references(:users, on_delete: :nothing, type: :integer)

      timestamps(type: :utc_datetime)
    end

    create index(:chat_rooms, [:owner_id])
  end
end
