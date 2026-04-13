defmodule Todo.CardTest do
  use Todo.DataCase, async: true

  alias Todo.Card

  describe "card/schema" do
    test "title is required" do
      changeset = Card.changeset(%Card{}, %{description: "description text"})

      assert %{title: ["can't be blank"]} = errors_on(changeset)
    end

    test "description should be less than 5000 chars" do
      changeset =
        Card.changeset(%Card{}, %{
          title: Faker.Person.first_name(),
          description: String.duplicate("a", 5001)
        })

      assert %{description: ["should be at most 5000 character(s)"]} = errors_on(changeset)
    end
  end
end
