defmodule Todo.Repo.Migrations.CreateCards do
  use Ecto.Migration

  def change do
    create table(:cards) do
      add :title, :string, null: false
      add :description, :string
      add :state, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create constraint(:cards, :state_must_be_valid, check: "state IN ('todo', 'doing', 'done')")
  end
end
