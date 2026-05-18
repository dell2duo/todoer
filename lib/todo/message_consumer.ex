defmodule MessageConsumer do
  use Broadway

  require Logger
  alias TodoWeb.Endpoint
  alias Broadway.Message

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module:
          {BroadwayRabbitMQ.Producer,
           queue: "todo_notifications",
           qos: [
             prefetch_count: 50
           ],
           on_failure: :reject_and_requeue},
        concurrency: 1
      ],
      processors: [
        default: [
          concurrency: 50
        ]
      ]
      # batchers: [
      #   default: [
      #     batch_size: 10,
      #     batch_timeout: 1500,
      #     concurrency: 5
      #   ]
      # ]
    )
  end

  @impl true
  def handle_message(_, %Message{data: data} = message, _) do
    case Jason.decode(data) do
      {:ok, %{"event" => "card_created"} = payload} ->
        notify(payload)
        message

      {:ok, payload} ->
        Logger.warning("Unknown event: #{inspect(payload)}")
    end
  end

  # @impl true
  # def handle_batch(_, messages, _, _) do
  #   list = messages |> Enum.map(fn e -> e.data end)
  #   IO.inspect(list, label: "Got batch")
  #   messages
  # end

  defp notify(payload) do
    Logger.info("Card created -> #{inspect(payload)}")
    Endpoint.broadcast("board", "created_card", payload)
  end
end
