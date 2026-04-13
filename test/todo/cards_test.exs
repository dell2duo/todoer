defmodule Todo.CardsTest do
  use Todo.DataCase, async: true

  alias Todo.Cards
  alias Todo.Card

  describe "cards" do
    test "list_cards/0 returns all cards" do
      card1 = Repo.insert!(%Card{title: "Card 1"})
      card2 = Repo.insert!(%Card{title: "Card 2"})

      cards = Cards.list_cards()

      assert card1 in cards
      assert card2 in cards
    end

    test "move_card_forward/1 can move when state is `:todo`" do
      card = Repo.insert!(%Card{title: "Card 1"})

      assert card.state == :todo

      {:ok, moved_card} = Cards.move_card_forward(card.id)

      assert moved_card.state == :doing
    end

    test "move_card_forward/1 can move when state is `:doing`" do
      card = Repo.insert!(%Card{title: "Card 1", state: :doing})

      {:ok, moved_card} = Cards.move_card_forward(card.id)

      assert moved_card.state == :done
    end

    test "move_card_forward/1 can't move forward if status `:done`" do
      card = Repo.insert!(%Card{title: "Card 1", state: :done})

      {:error, reason} = Cards.move_card_forward(card.id)

      assert reason == "can't move forward"
    end

    test "move_card_backwards/1 can't move when state is `:todo`" do
      card = Repo.insert!(%Card{title: "Card 1"})

      assert card.state == :todo

      {:error, reason} = Cards.move_card_backwards(card.id)

      assert reason == "can't move backwards"
    end

    test "move_card_backwards/1 can move when state is `:doing`" do
      card = Repo.insert!(%Card{title: "Card 1", state: :doing})

      {:ok, moved_card} = Cards.move_card_backwards(card.id)

      assert moved_card.state == :todo
    end

    test "move_card_backwards/1 can move backwards if status `:done`" do
      card = Repo.insert!(%Card{title: "Card 1", state: :done})

      {:ok, moved_card} = Cards.move_card_backwards(card.id)

      assert moved_card.state == :doing
    end
  end
end
