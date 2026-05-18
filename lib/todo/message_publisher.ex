defmodule Todo.MessagePublisher do
  alias AMQP.Basic
  alias AMQP.Channel
  alias AMQP.Connection

  alias Todo.Card

  def publish_create_card(%Card{id: id, title: title}) do
    config = Application.fetch_env!(:todo, Todo.RabbitMQ)

    payload =
      Jason.encode!(%{
        event: :card_created,
        card_id: id,
        card_title: title
      })

    with {:ok, conn} <- Connection.open(config[:connection]),
         {:ok, chan} <- Channel.open(conn),
         :ok <- Basic.publish(chan, "", config[:queue], payload, persist: true) do
      Channel.close(chan)
      Connection.close(conn)
    end
  end
end
