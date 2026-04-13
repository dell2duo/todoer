defmodule Todo.Card do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cards" do
    field :title, :string
    field :description, :string
    field :state, Ecto.Enum, values: [:todo, :doing, :done], default: :todo

    timestamps(type: :utc_datetime)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:title, :description, :state])
    |> validate_length(:description, max: 5000)
    |> validate_required([:title])
  end
end
