defmodule Todo.Repo.Migrations.ChangeCardDescriptionType do
  use Ecto.Migration

  def change do
    alter table(:cards) do
      modify :description, :text
    end

    create constraint(:cards, :description_length, check: "char_length(description) <= 5000")
  end
end
