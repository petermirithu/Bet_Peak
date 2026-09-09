defmodule BetPeakWeb.BetLive.Index do
  use BetPeakWeb, :live_view

  alias BetPeak.Games
  alias BetPeakWeb.Helpers
  alias BetPeak.Bets
  alias BetPeak.Bets.Bet

  embed_templates "index/*"

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(games: Games.fetch_active())
     |> handle_bets_loading()
     |> assign(show_bet_modal: false)
     |> assign(modal_operation: "")
     |> assign(selected_game: %{})
     |> assign(selected_bet: %{})
     |> assign(odds_at_placement: Decimal.new("0.0"))
     |> assign(potential_payout: Decimal.new("0.0"))
     |> assign(form: nil)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    case assigns.live_action do
      :home -> home_html(assigns)
      :bets_placed -> bets_html(assigns)
      :bets_history -> bets_html(assigns)
    end
  end

  defp handle_bets_loading(socket) do
    case socket.assigns.live_action do
      :bets_placed ->
        assign(socket, bets: Bets.fetch_active(socket.assigns.current_scope.user.id))

      :bets_history ->
        history = Bets.fetch_history(socket.assigns.current_scope.user.id)

        socket
        |> assign(bets: history.bets)
        |> assign(won: history.won)
        |> assign(lost: history.lost)

      :home ->
        socket
    end
  end

  @impl true
  def handle_event("open_bet_modal", %{"operation" => operation, "game_id" => game_id}, socket) do
    # For adding a new bet
    game = Enum.find(socket.assigns.games, &(&1.id == String.to_integer(game_id)))

    changeset = Bets.change_bet_creation(%Bet{}, %{}, validate_unique: false)

    {
      :noreply,
      socket
      |> assign(selected_game: game)
      |> assign(modal_operation: operation)
      |> assign_form(changeset)
      |> assign(show_bet_modal: true)
    }
  end

  def handle_event("open_bet_modal", %{"operation" => operation, "bet_id" => bet_id}, socket) do
    # For editting and deleting an already existing bet
    bet = Enum.find(socket.assigns.bets, &(&1.id == String.to_integer(bet_id)))

    case operation do
      "edit" ->
        changeset = Bets.change_bet_creation(bet, %{}, validate_unique: false)

        {
          :noreply,
          socket
          |> assign(odds_at_placement: bet.odds_at_placement)
          |> assign(potential_payout: bet.potential_payout)
          |> assign(selected_bet: bet)
          |> assign(modal_operation: operation)
          |> assign_form(Map.put(changeset, :action, :validate))
          |> assign(show_bet_modal: true)
        }

      "delete" ->
        {
          :noreply,
          socket
          |> assign(selected_bet: bet)
          |> assign(modal_operation: operation)
          |> assign(show_bet_modal: true)
        }
    end
  end

  @impl true
  def handle_event("close_bet_modal", _params, socket) do
    {
      :noreply,
      socket
      |> assign(show_bet_modal: false)
      |> assign(modal_operation: "")
      |> assign(selected_game: %{})
    }
  end

  @impl true
  def handle_event("save_bet", %{"bet" => bet_params}, socket) do
    new_bet_params =
      bet_params
      |> Map.put("user_id", socket.assigns.current_scope.user.id)
      |> Map.put("game_id", socket.assigns.selected_game.id)

    case Bets.save_bet(new_bet_params) do
      {:ok, _bet} ->
        {:noreply,
         socket
         |> put_flash(:info, "Successfully placed the bet")
         |> assign(show_bet_modal: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("update_bet", %{"bet" => bet_params}, socket) do
    new_bet_params = Map.put(bet_params, "user_id", socket.assigns.current_scope.user.id)

    case Bets.update_bet(socket.assigns.selected_bet, new_bet_params) do
      {:ok, _bet} ->
        {:noreply,
         socket
         |> handle_bets_loading()
         |> put_flash(:info, "Successfully updated the bet")
         |> assign(show_bet_modal: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("delete_bet", _params, socket) do
    case Bets.delete_bet(socket.assigns.selected_bet) do
      {:ok, _bet} ->
        {:noreply,
         socket
         |> handle_bets_loading()
         |> put_flash(:info, "Successfully deleted the bet")
         |> assign(show_bet_modal: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> put_flash(:info, "Oops! Something went wrong while deleting the bet.")
         |> assign(show_bet_modal: false)}
    end
  end

  @impl true
  def handle_event("validate_bet_form", %{"bet" => bet_params}, socket) do
    %{new_bet_params: new_bet_params, bet: bet} =
      if socket.assigns.modal_operation == "add" do
        %{
          new_bet_params:
            bet_params
            |> Map.put("user_id", socket.assigns.current_scope.user.id)
            |> Map.put("game_id", socket.assigns.selected_game.id),
          bet: %Bet{}
        }
      else
        %{new_bet_params: bet_params, bet: socket.assigns.selected_bet}
      end

    changeset = Bets.change_bet_creation(bet, new_bet_params, validate_unique: false)

    {:noreply,
     socket
     |> assign(
       odds_at_placement:
         get_odds_at_placement(
           socket,
           changeset
           |> Map.get(:changes)
           |> Map.get(:odds_at_placement, Decimal.new("0.0")),
           bet
         )
     )
     |> assign(
       potential_payout:
         get_potential_payout(
           socket,
           changeset |> Map.get(:changes) |> Map.get(:potential_payout, Decimal.new("0.0")),
           bet
         )
     )
     |> assign_form(Map.put(changeset, :action, :validate))}
  end

  defp get_odds_at_placement(socket, value, bet) do
    if value == Decimal.new("0.0") and socket.assigns.selected_bet != %{} do
      socket.assigns.selected_bet.odds_at_placement
    else
      value
    end
  end

  defp get_potential_payout(socket, value, bet) do
    if value == Decimal.new("0.0") and socket.assigns.selected_bet != %{} do
      socket.assigns.selected_bet.potential_payout
    else
      value
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "bet")
    assign(socket, form: form)
  end

  @impl true
  def handle_event("go_to_home_to_place_bet", _params, socket) do
    {:noreply,
     socket
     |> redirect(to: ~p"/#featured-games")}
  end

  def bet_modal(assigns) do
    ~H"""
    <dialog
      id="bet-modal"
      class="modal bg-[#161616]/55 backdrop-blur-sm"
      open={@show_bet_modal}
      aria-labelledby="bet-modal-title"
      phx-window-keydown="close_bet_modal"
      phx-key="escape"
    >
      <div class="modal-box max-h-[90vh] max-w-3xl overflow-y-auto rounded-lg bg-[#f8f6f0] p-0 text-[#161616] shadow-2xl">
        <button
          id="close-bet-modal"
          type="button"
          class="absolute right-4 top-4 rounded-2xl z-10 grid size-9 cursor-pointer place-items-center bg-black/5 text-[#161616]/55 transition hover:bg-black/10 hover:text-[#161616]"
          phx-click="close_bet_modal"
          aria-label="Close bet details"
        >
          <.icon name="hero-x-mark" class="size-5" />
        </button>

        <div>
          <header class="flex items-center gap-4 border-b border-[#ded9ce] px-6 py-6 sm:px-8">
            <div class="min-w-0 pr-10">
              <div class="flex flex-wrap items-center gap-2">
                <h2 id="bet-modal-title" class="truncate text-xl font-extrabold">
                  <span :if={@modal_operation == "add"}>
                    Place a Bet for:
                    <span :if={@selected_game != %{}}>{@selected_game.home_team.short_form} VS {@selected_game.away_team.short_form}</span>
                  </span>
                  <span :if={@modal_operation == "edit"}>
                    Edit the Bet for:
                    <span :if={@selected_bet != %{}}>{@selected_bet.game.home_team.short_form} VS {@selected_bet.game.away_team.short_form}</span>
                  </span>
                </h2>
              </div>
            </div>
          </header>

          <div :if={@modal_operation == "add" or @modal_operation == "edit"} class="p-6 sm:p-8">
            <div class="mb-6">
              <p class="mt-1 text-sm text-[#161616]/50">
                {if(@modal_operation == "add",
                  do: "Fill in all fields to place a new bet!",
                  else: "Update the bet!"
                )}
              </p>
            </div>
            <.form
              :if={@form}
              for={@form}
              id="bet_form"
              phx-change="validate_bet_form"
              phx-submit={if(@modal_operation == "add", do: "save_bet", else: "update_bet")}
              class="space-y-6"
            >
              <div class="grid grid-cols-2 gap-1">
                <div>
                  <.input
                    field={@form[:selection]}
                    type="select"
                    label="Selection"
                    options={[
                      Home: "home",
                      Draw: "draw",
                      Away: "away"
                    ]}
                    spellcheck="false"
                    required
                    class="h-12 select rounded-2xl w-full border border-[#d7d2c7] bg-white px-4 text-[#161616] outline-none transition placeholder:text-[#161616]/30 focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                    error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                  />
                </div>
                <div>
                  <.input
                    field={@form[:stake_amount]}
                    type="number"
                    label="Stake Amount in KES"
                    placeholder="e.g. Minimum amount is KES 100.0"
                    required
                    class="h-12 rounded-2xl w-full border border-[#d7d2c7] bg-white px-4 text-[#161616] outline-none transition placeholder:text-[#161616]/30 focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                    error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                  />
                </div>

                <p class="text-left text-xs font-semibold text-[#161616]/35">
                  Odds at Placement: {@odds_at_placement}
                </p>
                <p class="text-left text-xs font-semibold text-[#161616]/35">
                  Possible Payout is: KES {@potential_payout}
                </p>
              </div>

              <div class="flex justify-end border-t border-[#ded9ce] pt-5">
                <.button
                  phx-disable-with="Saving bet ..."
                  class="group rounded-2xl flex h-11 items-center justify-center gap-2 bg-[#161616] px-6 text-sm font-bold text-white transition hover:bg-[#735700] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#b28708]"
                >
                  Save Bet
                  <.icon
                    name="hero-arrow-right-mini"
                    class="size-4 transition-transform group-hover:translate-x-1"
                  />
                </.button>
              </div>
            </.form>
          </div>

          <div :if={@modal_operation == "delete"} class="p-6 sm:p-8">
            <div class="border-l-4 border-red-500 bg-red-50 p-5">
              <div class="flex gap-3">
                <.icon name="hero-exclamation-triangle" class="mt-0.5 size-5 shrink-0 text-red-600" />
                <div>
                  <h3 class="font-bold text-red-950">Delete this bet?</h3>
                  <p class="font-extrabold italic mt-2 mb-2">
                    {@selected_bet.game.home_team.name} VS {@selected_bet.game.away_team.name}
                  </p>

                  <p class="text-sm text-red-950">Selection: {@selected_bet.selection}</p>
                  <p class="text-sm text-red-950">Stake Amount: KES {@selected_bet.stake_amount}</p>
                  <p class="text-sm text-red-950">
                    Potential Payout: KES {@selected_bet.potential_payout}
                  </p>
                  <p class="mt-1 text-sm leading-6 text-red-900/65">
                    This permanently removes the bet and all associated data.
                  </p>
                </div>
              </div>
            </div>
            <div class="flex justify-end border-t border-[#ded9ce] pt-5">
              <.button
                phx-disable-with="Deleting bet..."
                class="mt-5 rounded-2xl flex h-11 items-center justify-center gap-2 bg-red-600 px-6 text-sm font-bold text-white transition hover:bg-red-700 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600"
                phx-click="delete_bet"
                phx-value-bet_id={@selected_bet.id}
              >
                <.icon name="hero-trash" class="size-4" /> Delete bet
              </.button>
            </div>
          </div>
        </div>
      </div>
      <button class="modal-backdrop" phx-click="close_bet_modal" aria-label="Close bet details">
        close
      </button>
    </dialog>
    """
  end
end
