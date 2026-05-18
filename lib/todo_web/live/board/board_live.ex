defmodule TodoWeb.BoardLive do
  require Logger
  alias TodoWeb.Endpoint
  alias Todo.MessagePublisher
  use TodoWeb, :live_view

  alias Todo.{Card, Cards}

  def mount(_params, _session, socket) do
    Endpoint.subscribe("board")

    cards = Cards.list_cards()

    {:ok,
     socket
     |> assign(:form, to_form(Cards.change_card(%Card{}), as: :card))
     |> assign(:cards, cards)}
  end

  def handle_event("create-task", %{"card" => card}, socket) do
    case Cards.create_card(card) do
      {:ok, card} ->
        MessagePublisher.publish_create_card(card)

        {:noreply,
         socket |> add_card(card) |> push_event("hide-modal", %{modal: "create-todo-modal"})}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("validate", %{"card" => params}, socket) do
    form =
      %Card{}
      |> Cards.change_card(params)
      |> to_form(action: :validate)

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("clear-form", _, socket),
    do: {:noreply, assign(socket, form: to_form(Cards.change_card(%Card{}), as: :card))}

  def handle_event("next-column", %{"card" => card_id}, socket) do
    case Cards.move_card_forward(card_id) do
      {:ok, card} ->
        {:noreply, socket |> move_card(card)}

      {:error, reason} ->
        Logger.error(reason)
        {:noreply, socket}
    end
  end

  def handle_event("previous-column", %{"card" => card_id}, socket) do
    case Cards.move_card_backwards(card_id) do
      {:ok, card} ->
        {:noreply, socket |> move_card(card)}

      {:error, reason} ->
        Logger.error(reason)
        {:noreply, socket}
    end
  end

  def handle_info(
        %{event: "created_card", payload: %{"card_title" => card_title}} = _event,
        socket
      ) do
    Logger.info("New message broadcast #{card_title}")
    # TODO: make flash component for :success
    socket = put_flash(socket, :info, "Card #{card_title} was created")
    {:noreply, socket}
  end

  defp move_card(socket, card) do
    socket
    |> assign(
      :cards,
      socket.assigns.cards
      |> Enum.map(fn
        %{id: id} = _map when id == card.id -> card
        map -> map
      end)
    )
  end

  defp add_card(socket, card) do
    socket
    |> assign(:cards, [card | socket.assigns.cards])
  end

  defp column_title(state) do
    case state do
      :todo -> "To Do"
      :doing -> "Doing"
      _ -> "Done"
    end
  end

  defp column_title_color(state) do
    case state do
      :todo -> "warning"
      :doing -> "primary"
      _ -> "success"
    end
  end

  defp column(assigns) do
    ~H"""
    <div id={"#{@state}-column"} class="w-1/3 space-y-2 bg-base-300 p-3 rounded-xl">
      <h2 class={"w-full text-center text-#{column_title_color(@state)} font-black text-2xl"}>
        {column_title(@state)}
      </h2>
      <div class="space-y-6 bg-base-200 p-4 py-6 rounded-2xl">
        <div
          :for={card <- @cards |> Enum.filter(&(&1.state == @state))}
          id={"card-#{card.id}"}
          class="bg-base-300 p-4 shadow-lg space-y-4"
        >
          <h3 class="text-xl font-bold">{card.title}</h3>

          <div :if={card.description} class="space-y-2">
            <h3 class="text-xs text-primary">Description</h3>
            <p>{card.description}</p>
          </div>

          <div>
            <.button
              :if={@state != :todo}
              type="button"
              phx-click="previous-column"
              phx-value-card={card.id}
            >
              <.icon name="hero-arrow-left" />
            </.button>
            <.button
              :if={@state != :done}
              type="button"
              phx-click="next-column"
              phx-value-card={card.id}
            >
              <.icon name="hero-arrow-right" />
            </.button>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
