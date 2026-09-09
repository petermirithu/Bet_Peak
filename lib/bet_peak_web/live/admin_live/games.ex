defmodule BetPeakWeb.AdminLive.Games do
  use BetPeakWeb, :live_view

  alias BetPeakWeb.Helpers
  alias BetPeak.Games
  alias BetPeak.Games.Game
  alias BetPeak.Teams

  @impl true
  def mount(_params, _session, socket) do
    teams =
      Teams.fetch_all()
      |> Enum.map(&{String.to_atom("#{&1.name}"), &1.id})

    {
      :ok,
      socket
      |> assign(teams: teams)
      |> assign(games: Games.fetch_all())
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
        changeset = Games.change_game_creation(%Game{}, %{}, validate_unique: false)

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
    new_game_params = Map.put(game_params, "user_id", socket.assigns.current_scope.user.id)

    case Games.save_game(new_game_params) do
      {:ok, _game} ->
        {:noreply,
         socket
         |> assign(games: Games.fetch_all())
         |> put_flash(:info, "Successfully created the game")
         |> assign(show_game_modal: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("update_game", %{"game" => game_params}, socket) do
    new_game_params = Map.put(game_params, "user_id", socket.assigns.current_scope.user.id)

    case Games.update_game(socket.assigns.selected_game, new_game_params) do
      {:ok, _game} ->
        {:noreply,
         socket
         |> assign(games: Games.fetch_all())
         |> put_flash(:info, "Successfully updated the game")
         |> assign(show_game_modal: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("delete_game", _params, socket) do
    case Games.delete_game(socket.assigns.selected_game) do
      {:ok, _game} ->
        {:noreply,
         socket
         |> assign(games: Games.fetch_all())
         |> put_flash(:info, "Successfully delete the game")
         |> assign(show_game_modal: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> put_flash(:info, "Oops! Something went wrong while deleting the game.")
         |> assign(show_game_modal: false)}
    end
  end

  @impl true
  def handle_event("validate_game_form", %{"game" => game_params}, socket) do
    new_game_params = Map.put(game_params, "user_id", socket.assigns.current_scope.user.id)
    changeset = Games.change_game_creation(%Game{}, new_game_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "game")
    assign(socket, form: form)
  end

  def game_modal(assigns) do
    ~H"""
    <dialog
      id="game-modal"
      class="modal bg-[#161616]/55 backdrop-blur-sm"
      open={@show_game_modal}
      aria-labelledby="game-modal-title"
      phx-window-keydown="close_game_modal"
      phx-key="escape"
    >
      <div class="modal-box max-h-[90vh] max-w-3xl overflow-y-auto rounded-lg bg-[#f8f6f0] p-0 text-[#161616] shadow-2xl">
        <button
          id="close-game-modal"
          type="button"
          class="absolute right-4 top-4 rounded-2xl z-10 grid size-9 cursor-pointer place-items-center bg-black/5 text-[#161616]/55 transition hover:bg-black/10 hover:text-[#161616]"
          phx-click="close_game_modal"
          aria-label="Close game details"
        >
          <.icon name="hero-x-mark" class="size-5" />
        </button>

        <div>
          <header class="flex items-center gap-4 border-b border-[#ded9ce] px-6 py-6 sm:px-8">
            <div class="min-w-0 pr-10">
              <div class="flex flex-wrap items-center gap-2">
                <h2 id="game-modal-title" class="truncate text-xl font-extrabold">
                  <span :if={@modal_operation == "add"}>Add New Game</span>
                  <span :if={@modal_operation == "edit" or @modal_operation == "delete"}>
                    {"Game: #{@selected_game.home_team.short_form} VS #{@selected_game.away_team.short_form}"}
                  </span>
                </h2>
              </div>
            </div>
          </header>

          <div :if={@modal_operation == "add" or @modal_operation == "edit"} class="p-6 sm:p-8">
            <div class="mb-6">
              <p class="mt-1 text-sm text-[#161616]/50">
                {if(@modal_operation == "add",
                  do: "Fill in all fields to save a new game!",
                  else: "Update the game!"
                )}
              </p>
            </div>
            <.form
              :if={@form}
              for={@form}
              id="game_form"
              phx-change="validate_game_form"
              phx-submit={if(@modal_operation == "add", do: "save_game", else: "update_game")}
              class="grid gap-x-4 sm:grid-cols-2"
            >
              <div>
                <.input
                  field={@form[:home_team_id]}
                  type="select"
                  label="Select Home Team"
                  options={@teams}
                  spellcheck="false"
                  required
                  class="h-12 select rounded-2xl w-full border border-[#d7d2c7] bg-white px-4 text-[#161616] outline-none transition placeholder:text-[#161616]/30 focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                  error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                />
              </div>
              <div>
                <.input
                  field={@form[:away_team_id]}
                  type="select"
                  label="Select Away Team"
                  options={@teams}
                  spellcheck="false"
                  required
                  class="h-12 select rounded-2xl w-full border border-[#d7d2c7] bg-white px-4 text-[#161616] outline-none transition placeholder:text-[#161616]/30 focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                  error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                />
              </div>
              <div class="grid gap-x-4 sm:grid-cols-3 sm:col-span-2">
                <div>
                  <.input
                    field={@form[:home_odds]}
                    type="number"
                    label="Home odds"
                    spellcheck="false"
                    required
                    class="h-12 rounded-2xl w-full border border-[#d7d2c7] bg-white px-4 text-[#161616] outline-none transition placeholder:text-[#161616]/30 focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                    error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                  />
                </div>
                <div>
                  <.input
                    field={@form[:draw_odds]}
                    type="number"
                    label="Draw odds"
                    spellcheck="false"
                    required
                    class="h-12 rounded-2xl w-full border border-[#d7d2c7] bg-white px-4 text-[#161616] outline-none transition placeholder:text-[#161616]/30 focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                    error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                  />
                </div>
                <div>
                  <.input
                    field={@form[:away_odds]}
                    type="number"
                    label="Away odds"
                    spellcheck="false"
                    required
                    class="h-12 rounded-2xl w-full border border-[#d7d2c7] bg-white px-4 text-[#161616] outline-none transition placeholder:text-[#161616]/30 focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                    error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                  />
                </div>
              </div>
              <div class={if(@modal_operation == "edit", do: "", else: "sm:col-span-2")}>
                <.input
                  field={@form[:starts_at]}
                  type="datetime-local"
                  label="Starts at"
                  spellcheck="false"
                  required
                  class="h-12 rounded-2xl w-full border border-[#d7d2c7] bg-white px-4 text-[#161616] outline-none transition placeholder:text-[#161616]/30 focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                  error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                />
              </div>
              <div :if={@modal_operation == "edit"}>
                <.input
                  field={@form[:result]}
                  type="select"
                  label="Select Game Result"
                  options={[
                    Pending: "pending",
                    "Home Team Won": "home",
                    "Away Team Won": "away",
                    "Teams Drew": "draw"
                  ]}
                  spellcheck="false"
                  required="false"
                  class="h-12 select rounded-2xl w-full border border-[#d7d2c7] bg-white px-4 text-[#161616] outline-none transition placeholder:text-[#161616]/30 focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                  error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                />
              </div>

              <div :if={@modal_operation == "edit"} class="sm:col-span-2">
                <.input
                  field={@form[:status]}
                  type="select"
                  label="Select Game Status"
                  options={[
                    Scheduled: "scheduled",
                    Live: "live",
                    Finished: "finished",
                    Cancelled: "cancelled"
                  ]}
                  spellcheck="false"
                  required
                  class="h-12 select rounded-2xl w-full border border-[#d7d2c7] bg-white px-4 text-[#161616] outline-none transition placeholder:text-[#161616]/30 focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                  error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                />
              </div>

              <div class="flex sm:col-span-2 justify-end border-t border-[#ded9ce] pt-5">
                <.button
                  phx-disable-with="Saving game ..."
                  class="group rounded-2xl flex h-11 items-center justify-center gap-2 bg-[#161616] px-6 text-sm font-bold text-white transition hover:bg-[#735700] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#b28708]"
                >
                  Save game
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
                  <h3 class="font-bold text-red-950">Delete this game?</h3>
                  <p class="font-extrabold italic mt-2 mb-2">
                    {@selected_game.home_team.name} VS {@selected_game.away_team.name}
                  </p>
                  <p class="mt-1 text-sm leading-6 text-red-900/65">
                    This permanently removes the game and all associated data.
                  </p>
                </div>
              </div>
            </div>
            <div class="flex justify-end border-t border-[#ded9ce] pt-5">
              <.button
                phx-disable-with="Deleting game..."
                class="mt-5 rounded-2xl flex h-11 items-center justify-center gap-2 bg-red-600 px-6 text-sm font-bold text-white transition hover:bg-red-700 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600"
                phx-click="delete_game"
                phx-value-game_id={@selected_game.id}
              >
                <.icon name="hero-trash" class="size-4" /> Delete game
              </.button>
            </div>
          </div>
        </div>
      </div>
      <button class="modal-backdrop" phx-click="close_game_modal" aria-label="Close game details">
        close
      </button>
    </dialog>
    """
  end
end
