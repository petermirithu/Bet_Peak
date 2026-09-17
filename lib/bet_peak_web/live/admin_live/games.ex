defmodule BetPeakWeb.AdminLive.Games do
  use BetPeakWeb, :live_view

  alias BetPeakWeb.Helpers
  alias BetPeak.Games
  alias BetPeak.Games.Game
  alias BetPeak.Teams

  @impl true
  def mount(_params, _session, socket) do
    teams =
      Teams.fetch_all(socket.assigns.current_scope)
      |> Enum.map(&{&1.name, &1.id})

    {
      :ok,
      socket
      |> assign(teams: teams)
      |> assign(games: Games.fetch_all(socket.assigns.current_scope))
      |> assign(show_game_modal: false)
      |> assign(modal_operation: "")
      |> assign(selected_game: %{})
      |> assign(form: nil)
    }
  end

  @impl true
  def handle_event(
        "open_game_modal",
        %{"operation" => operation, "game_id" => game_id},
        socket
      ) do
    case operation do
      "add" ->
        changeset =
          Games.change_game_creation(%Game{}, %{}, validate_unique: false)

        {
          :noreply,
          socket
          |> assign(show_game_modal: true)
          |> assign(modal_operation: operation)
          |> assign_form(changeset)
        }

      "edit" ->
        game = Enum.find(socket.assigns.games, &(&1.id == String.to_integer(game_id)))
        changeset = Games.change_game_creation(game, %{}, validate_unique: false)

        {
          :noreply,
          socket
          |> assign(selected_game: game)
          |> assign(modal_operation: operation)
          |> assign_form(Map.put(changeset, :action, :validate))
          |> assign(show_game_modal: true)
        }

      "delete" ->
        game = Enum.find(socket.assigns.games, &(&1.id == String.to_integer(game_id)))

        {
          :noreply,
          socket
          |> assign(show_game_modal: true)
          |> assign(selected_game: game)
          |> assign(modal_operation: operation)
        }
    end
  end

  @impl true
  def handle_event("close_game_modal", _params, socket) do
    {
      :noreply,
      socket
      |> assign(show_game_modal: false)
      |> assign(modal_operation: "")
      |> assign(selected_game: %{})
    }
  end

  @impl true
  def handle_event("save_game", %{"game" => game_params}, socket) do
    new_game_params =
      game_params
      |> Map.put("user_id", socket.assigns.current_scope.user.id)
      |> Map.put("status", :scheduled)

    case Games.save_game(socket.assigns.current_scope, new_game_params) do
      {:ok, _game} ->
        {:noreply,
         socket
         |> assign(games: Games.fetch_all(socket.assigns.current_scope))
         |> put_flash(:info, "Successfully created the game")
         |> assign(show_game_modal: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        render_default_form_error(socket, changeset, "adding")

      {:error, :unauthorized} ->
        {:noreply, socket |> put_flash(:error, "You not authorized to create a game!")}

      {:error, _} ->
        render_default_form_error(socket, nil, "adding")
    end
  end

  @impl true
  def handle_event("update_game", %{"game" => game_params}, socket) do
    new_game_params = Map.put(game_params, "user_id", socket.assigns.current_scope.user.id)

    case Games.update_game(
           socket.assigns.current_scope,
           socket.assigns.selected_game,
           new_game_params
         ) do
      {:ok, _game} ->
        {:noreply,
         socket
         |> assign(games: Games.fetch_all(socket.assigns.current_scope))
         |> put_flash(:info, "Successfully updated the game")
         |> assign(show_game_modal: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        render_default_form_error(socket, changeset, "updating")

      {:error, :unauthorized} ->
        {:noreply, socket |> put_flash(:error, "You not authorized to update a game!")}

      {:error, _} ->
        render_default_form_error(socket, nil, "updating")
    end
  end

  @impl true
  def handle_event("delete_game", _params, socket) do
    case Games.delete_game(socket.assigns.current_scope, socket.assigns.selected_game) do
      {:ok, _game} ->
        {:noreply,
         socket
         |> assign(games: Games.fetch_all(socket.assigns.current_scope))
         |> put_flash(:info, "Successfully delete the game")
         |> assign(show_game_modal: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        render_default_form_error(socket, changeset, "deleting")

      {:error, :unauthorized} ->
        {:noreply, socket |> put_flash(:error, "You not authorized to delete a game!")}

      {:error, _} ->
        render_default_form_error(socket, nil, "deleting")
    end
  end

  @impl true
  def handle_event("validate_game_form", %{"game" => game_params}, socket) do
    new_game_params = Map.put(game_params, "user_id", socket.assigns.current_scope.user.id)

    game =
      if socket.assigns.modal_operation == "edit" do
        socket.assigns.selected_game
      else
        %Game{}
      end

    changeset = Games.change_game_creation(game, new_game_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp render_default_form_error(socket, changeset, operation) do
    case changeset do
      nil ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "Oops! Something went wrong while #{operation} the game. Try again later."
         )
         |> assign(show_game_modal: false)}

      _ ->
        {:noreply,
         socket
         |> assign_form(changeset)
         |> put_flash(
           :error,
           "Oops! Something went wrong while #{operation} the game. Try again later."
         )
         |> assign(show_game_modal: false)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "game")
    assign(socket, form: form)
  end

  def game_modal(assigns) do
    ~H"""
    <dialog
      id="game-modal"
      open={@show_game_modal}
      aria-labelledby="game-modal-title"
      phx-window-keydown="close_game_modal"
      phx-key="escape"
      class={[
        "fixed inset-0 z-50 m-0 hidden h-screen max-h-none w-screen max-w-none",
        "items-center justify-center overflow-y-auto border-0 bg-transparent p-4",
        "open:flex"
      ]}
    >
      <.button
        id="game-modal-backdrop"
        type="button"
        phx-click="close_game_modal"
        aria-label="Close game dialog"
        class={[
          "absolute inset-0 cursor-default bg-[#161616]/60 backdrop-blur-sm",
          "transition-opacity"
        ]}
      >
        <span class="sr-only">Close</span>
      </.button>

      <div class={[
        "relative z-10 w-full max-w-3xl overflow-hidden rounded-3xl",
        "border border-white/40 bg-[#f8f6f0] text-[#161616]",
        "shadow-[0_30px_90px_rgba(0,0,0,0.35)]"
      ]}>
        <.button
          id="close-game-modal"
          type="button"
          phx-click="close_game_modal"
          aria-label="Close game dialog"
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

        <div :if={@show_game_modal}>
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
                <.icon name="hero-calendar-days" class="size-6" />
              </span>

              <div class="min-w-0">
                <p class="mb-1 text-xs font-bold text-[#947000]">Games management</p>
                <h2 id="game-modal-title" class="truncate text-xl font-extrabold sm:text-2xl">
                  <%= case @modal_operation do %>
                    <% "add" -> %>
                      Schedule new game
                    <% "edit" -> %>
                      Edit {@selected_game.home_team.short_form} vs {@selected_game.away_team.short_form}
                    <% "delete" -> %>
                      Delete {@selected_game.home_team.short_form} vs {@selected_game.away_team.short_form}
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
                  do: "Set the matchup, opening odds, and scheduled start time.",
                  else: "Update this game's matchup, odds, schedule, and outcome."
                )}
              </p>
            </div>

            <.form
              :if={@form}
              for={@form}
              id="game-form"
              phx-change="validate_game_form"
              phx-submit={if(@modal_operation == "add", do: "save_game", else: "update_game")}
              class="space-y-7"
            >
              <section class="rounded-2xl border border-[#ded9ce] bg-white p-5 shadow-sm sm:p-6">
                <div class="mb-5 flex items-start gap-3">
                  <span class="grid size-10 shrink-0 place-items-center rounded-xl bg-[#fff1b8] text-[#806000]">
                    <.icon name="hero-user-group" class="size-5" />
                  </span>
                  <div>
                    <h3 class="font-extrabold text-[#161616]">Matchup</h3>
                    <p class="mt-1 text-sm leading-5 text-[#161616]/50">
                      Select two different teams for this fixture.
                    </p>
                  </div>
                </div>

                <div class="grid gap-x-4 sm:grid-cols-2">
                  <.input
                    field={@form[:home_team_id]}
                    type="select"
                    label="Home team"
                    prompt="Select home team"
                    options={@teams}
                    required
                    class="h-12 w-full rounded-2xl border border-[#d7d2c7] bg-white px-4 text-[#161616] shadow-sm outline-none transition hover:border-[#b8ae9c] focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                    error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                  />
                  <.input
                    field={@form[:away_team_id]}
                    type="select"
                    label="Away team"
                    prompt="Select away team"
                    options={@teams}
                    required
                    class="h-12 w-full rounded-2xl border border-[#d7d2c7] bg-white px-4 text-[#161616] shadow-sm outline-none transition hover:border-[#b8ae9c] focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                    error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                  />
                </div>
              </section>

              <section class="rounded-2xl border border-[#ded9ce] bg-white p-5 shadow-sm sm:p-6">
                <div class="mb-5 flex items-start gap-3">
                  <span class="grid size-10 shrink-0 place-items-center rounded-xl bg-[#fff1b8] text-[#806000]">
                    <.icon name="hero-chart-bar" class="size-5" />
                  </span>
                  <div>
                    <h3 class="font-extrabold text-[#161616]">Market odds</h3>
                    <p class="mt-1 text-sm leading-5 text-[#161616]/50">
                      Enter decimal odds greater than 1.00 for each outcome.
                    </p>
                  </div>
                </div>

                <div class="grid gap-x-4 sm:grid-cols-3">
                  <.input
                    field={@form[:home_odds]}
                    type="number"
                    label="Home odds"
                    step="0.01"
                    min="1.01"
                    required
                    class="h-12 w-full rounded-2xl border border-[#d7d2c7] bg-white px-4 text-[#161616] shadow-sm outline-none transition hover:border-[#b8ae9c] focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                    error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                  />
                  <.input
                    field={@form[:draw_odds]}
                    type="number"
                    label="Draw odds"
                    step="0.01"
                    min="1.01"
                    required
                    class="h-12 w-full rounded-2xl border border-[#d7d2c7] bg-white px-4 text-[#161616] shadow-sm outline-none transition hover:border-[#b8ae9c] focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                    error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                  />
                  <.input
                    field={@form[:away_odds]}
                    type="number"
                    label="Away odds"
                    step="0.01"
                    min="1.01"
                    required
                    class="h-12 w-full rounded-2xl border border-[#d7d2c7] bg-white px-4 text-[#161616] shadow-sm outline-none transition hover:border-[#b8ae9c] focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                    error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                  />
                </div>
              </section>

              <section class="rounded-2xl border border-[#ded9ce] bg-white p-5 shadow-sm sm:p-6">
                <div class="mb-5 flex items-start gap-3">
                  <span class="grid size-10 shrink-0 place-items-center rounded-xl bg-[#fff1b8] text-[#806000]">
                    <.icon name="hero-clock" class="size-5" />
                  </span>
                  <div>
                    <h3 class="font-extrabold text-[#161616]">Schedule and result</h3>
                    <p class="mt-1 text-sm leading-5 text-[#161616]/50">
                      Set kickoff time and update the game state as play progresses.
                    </p>
                  </div>
                </div>

                <div class="grid gap-x-4 sm:grid-cols-2">
                  <div class={if(@modal_operation == "edit", do: "", else: "sm:col-span-2")}>
                    <.input
                      field={@form[:starts_at]}
                      type="datetime-local"
                      label="Starts at"
                      required
                      class="h-12 w-full rounded-2xl border border-[#d7d2c7] bg-white px-4 text-[#161616] shadow-sm outline-none transition hover:border-[#b8ae9c] focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                      error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                    />
                  </div>
                  <div :if={@modal_operation == "edit"}>
                    <.input
                      field={@form[:result]}
                      type="select"
                      label="Result"
                      options={[
                        Pending: "pending",
                        "Home team won": "home",
                        "Away team won": "away",
                        Draw: "draw"
                      ]}
                      class="h-12 w-full rounded-2xl border border-[#d7d2c7] bg-white px-4 text-[#161616] shadow-sm outline-none transition hover:border-[#b8ae9c] focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                      error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                    />
                  </div>
                  <div :if={@modal_operation == "edit"} class="sm:col-span-2">
                    <.input
                      field={@form[:status]}
                      type="select"
                      label="Game status"
                      options={[
                        Scheduled: "scheduled",
                        Live: "live",
                        Finished: "finished",
                        Cancelled: "cancelled"
                      ]}
                      required
                      class="h-12 w-full rounded-2xl border border-[#d7d2c7] bg-white px-4 text-[#161616] shadow-sm outline-none transition hover:border-[#b8ae9c] focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                      error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                    />
                  </div>
                </div>
              </section>

              <footer class="flex flex-col-reverse gap-3 border-t border-[#ded9ce] pt-6 sm:flex-row sm:justify-end">
                <.button
                  id="cancel-game-form"
                  type="button"
                  phx-click="close_game_modal"
                  class="inline-flex h-11 items-center justify-center rounded-xl border border-[#d7d2c7] bg-white px-5 text-sm font-bold text-[#161616] transition hover:bg-[#f2efe7] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#161616]/15"
                >
                  Cancel
                </.button>
                <.button
                  id="submit-game-form"
                  type="submit"
                  phx-disable-with="Saving game..."
                  class="group inline-flex h-11 items-center justify-center gap-2 rounded-xl bg-[#161616] px-6 text-sm font-bold text-white shadow-sm transition duration-200 hover:-translate-y-0.5 hover:bg-[#735700] hover:shadow-md focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#b28708]/40 disabled:cursor-wait disabled:opacity-60"
                >
                  {if(@modal_operation == "add", do: "Schedule game", else: "Save changes")}
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
                  <h3 class="font-extrabold text-red-950">Delete this game?</h3>
                  <p class="mt-1 text-sm leading-6 text-red-900/65">
                    This permanently removes
                    <strong>{@selected_game.home_team.name} vs {@selected_game.away_team.name}</strong>
                    and may affect associated bets.
                  </p>
                </div>
              </div>
            </div>

            <div class="mt-6 flex flex-col-reverse gap-3 border-t border-[#ded9ce] pt-6 sm:flex-row sm:justify-end">
              <.button
                id="cancel-delete-game"
                type="button"
                phx-click="close_game_modal"
                class="inline-flex h-11 items-center justify-center rounded-xl border border-[#d7d2c7] bg-white px-5 text-sm font-bold text-[#161616] transition hover:bg-[#f2efe7]"
              >
                Cancel
              </.button>
              <.button
                id="confirm-delete-game"
                type="button"
                phx-disable-with="Deleting game..."
                phx-click="delete_game"
                phx-value-game_id={@selected_game.id}
                class="inline-flex h-11 items-center justify-center gap-2 rounded-xl bg-red-600 px-6 text-sm font-bold text-white shadow-sm transition hover:-translate-y-0.5 hover:bg-red-700 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-red-600/35"
              >
                <.icon name="hero-trash" class="size-4" /> Delete game
              </.button>
            </div>
          </div>
        </div>
      </div>
    </dialog>
    """
  end
end
