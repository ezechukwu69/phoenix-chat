defmodule ElixirChat.NewMessage do
  alias ElixirChat.NewMessage
  defstruct [:text]

  def changeset(values) do
    newMessage = %NewMessage{}
    types = %{text: :string}
    {newMessage, types}
     |> Ecto.Changeset.cast(values, Map.keys(types))
     |> Ecto.Changeset.validate_required([:text])
  end
end
