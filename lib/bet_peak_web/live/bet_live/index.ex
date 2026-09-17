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
     |> assign(games: Games.fetch_active(socket.assigns.current_scope))
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
        assign(socket, bets: Bets.fetch_active(socket.assigns.current_scope))

      :bets_history ->
        history = Bets.fetch_history(socket.assigns.current_scope)

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
      |> assign(selected_bet: %{})
      |> assign(odds_at_placement: Decimal.new("0.0"))
      |> assign(potential_payout: Decimal.new("0.0"))
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
      |> assign(selected_bet: %{})
      |> assign(odds_at_placement: Decimal.new("0.0"))
      |> assign(potential_payout: Decimal.new("0.0"))
    }
  end

  @impl true
  def handle_event("save_bet", %{"bet" => bet_params}, socket) do
    new_bet_params =
      bet_params
      |> Map.put("user_id", socket.assigns.current_scope.user.id)
      |> Map.put("game_id", socket.assigns.selected_game.id)

    case Bets.save_bet(socket.assigns.current_scope, new_bet_params) do
      {:ok, _bet} ->
        {:noreply,
         socket
         |> put_flash(:info, "Successfully placed the bet")
         |> assign(show_bet_modal: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        render_default_form_error(socket, changeset, "saving")

      {:error, :unauthorized} ->
        {:noreply, socket |> put_flash(:error, "You not authorized to save a bet!")}

      {:error, _} ->
        render_default_form_error(socket, nil, "saving")
    end
  end

  @impl true
  def handle_event("update_bet", %{"bet" => bet_params}, socket) do
    new_bet_params = Map.put(bet_params, "user_id", socket.assigns.current_scope.user.id)

    case Bets.update_bet(
           socket.assigns.current_scope,
           socket.assigns.selected_bet,
           new_bet_params
         ) do
      {:ok, _bet} ->
        {:noreply,
         socket
         |> handle_bets_loading()
         |> put_flash(:info, "Successfully updated the bet")
         |> assign(show_bet_modal: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        render_default_form_error(socket, changeset, "updating")

      {:error, :unauthorized} ->
        {:noreply, socket |> put_flash(:error, "You not authorized to update a bet!")}

      {:error, _} ->
        render_default_form_error(socket, nil, "updating")
    end
  end

  @impl true
  def handle_event("delete_bet", _params, socket) do
    case Bets.delete_bet(socket.assigns.current_scope, socket.assigns.selected_bet) do
      {:ok, _bet} ->
        {:noreply,
         socket
         |> handle_bets_loading()
         |> put_flash(:info, "Successfully deleted the bet")
         |> assign(show_bet_modal: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        render_default_form_error(socket, changeset, "deleting")

      {:error, :unauthorized} ->
        {:noreply, socket |> put_flash(:error, "You not authorized to delete a bet!")}

      {:error, _} ->
        render_default_form_error(socket, nil, "deleting")
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
           |> Map.get(:odds_at_placement, Decimal.new("0.0"))
         )
     )
     |> assign(
       potential_payout:
         get_potential_payout(
           socket,
           changeset |> Map.get(:changes) |> Map.get(:potential_payout, Decimal.new("0.0"))
         )
     )
     |> assign_form(Map.put(changeset, :action, :validate))}
  end

  @impl true
  def handle_event("go_to_home_to_place_bet", _params, socket) do
    {:noreply,
     socket
     |> redirect(to: ~p"/#featured-games")}
  end

  defp render_default_form_error(socket, changeset, operation) do
    case changeset do
      nil ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "Oops! Something went wrong while #{operation} the bet. Try again later."
         )
         |> assign(show_bet_modal: false)}

      _ ->
        {:noreply,
         socket
         |> assign_form(changeset)
         |> put_flash(
           :error,
           "Oops! Something went wrong while #{operation} the bet. Try again later."
         )
         |> assign(show_bet_modal: false)}
    end
  end

  defp get_odds_at_placement(socket, value) do
    if value == Decimal.new("0.0") and socket.assigns.selected_bet != %{} do
      socket.assigns.selected_bet.odds_at_placement
    else
      value
    end
  end

  defp get_potential_payout(socket, value) do
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

  def bet_modal(assigns) do
    ~H"""
    <dialog
      id="bet-modal"
      open={@show_bet_modal}
      aria-labelledby="bet-modal-title"
      phx-window-keydown="close_bet_modal"
      phx-key="escape"
      class={[
        "fixed inset-0 z-50 m-0 hidden h-screen max-h-none w-screen max-w-none",
        "items-center justify-center overflow-y-auto border-0 bg-transparent p-4",
        "open:flex"
      ]}
    >
      <.button
        id="bet-modal-backdrop"
        type="button"
        phx-click="close_bet_modal"
        aria-label="Close bet dialog"
        class={[
          "absolute inset-0 cursor-default bg-[#161616]/60 backdrop-blur-sm",
          "transition-opacity"
        ]}
      >
        <span class="sr-only">Close</span>
      </.button>

      <div class={[
        "relative z-10 w-full max-w-xl overflow-hidden rounded-3xl",
        "border border-white/40 bg-[#f8f6f0] text-[#161616]",
        "shadow-[0_30px_90px_rgba(0,0,0,0.35)]"
      ]}>
        <.button
          id="close-bet-modal"
          type="button"
          phx-click="close_bet_modal"
          aria-label="Close bet dialog"
          class={[
            "absolute right-5 top-5 z-20 grid size-10 place-items-center rounded-full",
            "border border-[#ded9ce] bg-white text-[#161616]/55 shadow-sm",
            "transition duration-200 hover:rotate-90 hover:border-[#b28708]",
            "hover:text-[#161616] focus-visible:outline-none",
            "focus-visible:ring-2 focus-visible:ring-[#f4bf25]/50"
          ]}
        >
          <.icon name="hero-x-mark" class="size-5" />
        </.button>

        <div :if={@show_bet_modal}>
          <header class={[
            "relative overflow-hidden border-b border-[#ded9ce]",
            "bg-gradient-to-br from-white to-[#f4edda] px-6 py-7 sm:px-8"
          ]}>
            <div class="absolute -right-12 -top-16 size-40 rounded-full bg-[#f4bf25]/15 blur-2xl">
            </div>

            <div class="relative flex items-center gap-4 pr-12">
              <span class={[
                "grid size-12 shrink-0 place-items-center rounded-2xl",
                "bg-[#161616] text-white shadow-lg shadow-black/10"
              ]}>
                <.icon name="hero-ticket" class="size-6" />
              </span>

              <div class="min-w-0">
                <p class="mb-1 text-xs font-bold text-[#947000]">Bet slip</p>
                <h2 id="bet-modal-title" class="truncate text-xl font-extrabold sm:text-2xl">
                  <%= case @modal_operation do %>
                    <% "add" -> %>
                      {@selected_game.home_team.short_form} vs {@selected_game.away_team.short_form}
                    <% "edit" -> %>
                      Edit {@selected_bet.game.home_team.short_form} vs {@selected_bet.game.away_team.short_form}
                    <% "delete" -> %>
                      Delete bet
                  <% end %>
                </h2>
              </div>
            </div>
          </header>

          <div
            :if={@modal_operation in ["add", "edit"]}
            class="max-h-[calc(90vh-8rem)] overflow-y-auto p-6 sm:p-8"
          >
            <div class="mb-7">
              <p class="text-sm leading-6 text-[#161616]/55">
                {if(@modal_operation == "add",
                  do: "Choose an outcome and enter your stake to preview the potential return.",
                  else: "Update your selection or stake before the fixture begins."
                )}
              </p>
            </div>

            <.form
              :if={@form}
              for={@form}
              id="bet-form"
              phx-change="validate_bet_form"
              phx-submit={if(@modal_operation == "add", do: "save_bet", else: "update_bet")}
              class="space-y-7"
            >
              <section class="rounded-2xl border border-[#ded9ce] bg-white p-5 shadow-sm sm:p-6">
                <div class="mb-5 flex items-start gap-3">
                  <span class="grid size-10 shrink-0 place-items-center rounded-xl bg-[#fff1b8] text-[#806000]">
                    <.icon name="hero-banknotes" class="size-5" />
                  </span>
                  <div>
                    <h3 class="font-extrabold text-[#161616]">Wager details</h3>
                    <p class="mt-1 text-sm leading-5 text-[#161616]/50">
                      The minimum accepted stake is KES 100.
                    </p>
                  </div>
                </div>

                <div class="grid gap-x-4 sm:grid-cols-2">
                  <.input
                    field={@form[:selection]}
                    type="select"
                    label="Selection"
                    prompt="Choose an outcome"
                    options={[
                      Home: "home",
                      Draw: "draw",
                      Away: "away"
                    ]}
                    required
                    class="h-12 w-full rounded-2xl border border-[#d7d2c7] bg-white px-4 text-[#161616] shadow-sm outline-none transition hover:border-[#b8ae9c] focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                    error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                  />
                  <.input
                    field={@form[:stake_amount]}
                    type="number"
                    label="Stake amount (KES)"
                    placeholder="e.g. 500"
                    min="100.01"
                    step="0.01"
                    required
                    class="h-12 w-full rounded-2xl border border-[#d7d2c7] bg-white px-4 text-[#161616] shadow-sm outline-none transition placeholder:text-[#161616]/30 hover:border-[#b8ae9c] focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                    error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                  />
                </div>

                <dl class="mt-5 grid gap-3 sm:grid-cols-2">
                  <div class="rounded-xl border border-[#e4dfd4] bg-[#f8f6f0] px-4 py-3">
                    <dt class="text-xs font-bold text-[#161616]/45">Odds at placement</dt>
                    <dd class="mt-1 text-lg font-extrabold text-[#161616]">
                      {@odds_at_placement}
                    </dd>
                  </div>
                  <div class="rounded-xl border border-[#ead48b] bg-[#fff8dc] px-4 py-3">
                    <dt class="text-xs font-bold text-[#806000]">Potential payout</dt>
                    <dd class="mt-1 text-lg font-extrabold text-[#161616]">
                      KES {@potential_payout}
                    </dd>
                  </div>
                </dl>
              </section>

              <footer class="flex flex-col-reverse gap-3 border-t border-[#ded9ce] pt-6 sm:flex-row sm:justify-end">
                <.button
                  id="cancel-bet-form"
                  type="button"
                  phx-click="close_bet_modal"
                  class="inline-flex h-11 items-center justify-center rounded-xl border border-[#d7d2c7] bg-white px-5 text-sm font-bold text-[#161616] transition hover:bg-[#f2efe7] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#161616]/15"
                >
                  Cancel
                </.button>
                <.button
                  id="submit-bet-form"
                  type="submit"
                  phx-disable-with="Saving bet..."
                  class="group inline-flex h-11 items-center justify-center gap-2 rounded-xl bg-[#161616] px-6 text-sm font-bold text-white shadow-sm transition duration-200 hover:-translate-y-0.5 hover:bg-[#735700] hover:shadow-md focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#b28708]/40 disabled:cursor-wait disabled:opacity-60"
                >
                  {if(@modal_operation == "add", do: "Place bet", else: "Save changes")}
                  <.icon
                    name="hero-arrow-right-mini"
                    class="size-4 transition-transform group-hover:translate-x-1"
                  />
                </.button>
              </footer>
            </.form>
          </div>

          <div :if={@modal_operation == "delete"} class="p-6 sm:p-8">
            <div class="rounded-2xl border border-red-200 bg-red-50 p-5">
              <div class="flex gap-4">
                <span class="grid size-10 shrink-0 place-items-center rounded-xl bg-red-100 text-red-700">
                  <.icon name="hero-exclamation-triangle" class="size-5" />
                </span>
                <div>
                  <h3 class="font-extrabold text-red-950">Delete this bet?</h3>
                  <p class="mt-1 text-sm leading-6 text-red-900/65">
                    {@selected_bet.game.home_team.name} vs {@selected_bet.game.away_team.name}
                  </p>
                </div>
              </div>

              <dl class="mt-5 grid gap-3 border-t border-red-200 pt-4 sm:grid-cols-3">
                <div>
                  <dt class="text-xs font-bold text-red-900/45">Selection</dt>
                  <dd class="mt-1 text-sm font-extrabold capitalize text-red-950">
                    {@selected_bet.selection}
                  </dd>
                </div>
                <div>
                  <dt class="text-xs font-bold text-red-900/45">Stake</dt>
                  <dd class="mt-1 text-sm font-extrabold text-red-950">
                    KES {@selected_bet.stake_amount}
                  </dd>
                </div>
                <div>
                  <dt class="text-xs font-bold text-red-900/45">Potential payout</dt>
                  <dd class="mt-1 text-sm font-extrabold text-red-950">
                    KES {@selected_bet.potential_payout}
                  </dd>
                </div>
              </dl>
            </div>

            <div class="mt-6 flex flex-col-reverse gap-3 border-t border-[#ded9ce] pt-6 sm:flex-row sm:justify-end">
              <.button
                id="cancel-delete-bet"
                type="button"
                phx-click="close_bet_modal"
                class="inline-flex h-11 items-center justify-center rounded-xl border border-[#d7d2c7] bg-white px-5 text-sm font-bold text-[#161616] transition hover:bg-[#f2efe7]"
              >
                Cancel
              </.button>
              <.button
                id="confirm-delete-bet"
                type="button"
                phx-disable-with="Deleting bet..."
                phx-click="delete_bet"
                phx-value-bet_id={@selected_bet.id}
                class="inline-flex h-11 items-center justify-center gap-2 rounded-xl bg-red-600 px-6 text-sm font-bold text-white shadow-sm transition hover:-translate-y-0.5 hover:bg-red-700 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-red-600/35"
              >
                <.icon name="hero-trash" class="size-4" /> Delete bet
              </.button>
            </div>
          </div>
        </div>
      </div>
    </dialog>
    """
  end
end
