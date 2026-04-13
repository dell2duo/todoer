defmodule Todo.Cards do
  import Ecto.Query, warn: false
  alias Todo.{Repo, Card}

  def list_cards do
    Repo.all(Card)
  end

  def get_card!(id), do: Repo.get!(Card, id)

  def create_card(attrs \\ %{}) do
    Process.sleep(5000)

    %Card{}
    |> Card.changeset(attrs)
    |> Repo.insert()
  end

  def update_card(%Card{} = card, attrs) do
    card
    |> Card.changeset(attrs)
    |> Repo.update()
  end

  def delete_card(%Card{} = card) do
    Repo.delete(card)
  end

  def change_card(%Card{} = card, attrs \\ %{}) do
    Card.changeset(card, attrs)
  end

  def move_card_forward(card_id) do
    card_id
    |> get_card!()
    |> move(:forward)
  end

  def move_card_backwards(card_id) do
    card_id
    |> get_card!()
    |> move(:back)
  end

  defp move(%Card{state: :done} = card, :back = _direction),
    do: update_card(card, %{state: :doing})

  defp move(%Card{state: :doing} = card, :back = _direction),
    do: update_card(card, %{state: :todo})

  defp move(_card, :back = _direction),
    do: {:error, "can't move backwards"}

  defp move(%Card{state: :todo} = card, :forward = _direction),
    do: update_card(card, %{state: :doing})

  defp move(%Card{state: :doing} = card, :forward = _direction),
    do: update_card(card, %{state: :done})

  defp move(_card, :forward = _direction),
    do: {:error, "can't move forward"}
end
