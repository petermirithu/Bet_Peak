defmodule BetPeakWeb.AdminLive.Sports do
  use BetPeakWeb, :live_view

  alias BetPeakWeb.Helpers
  alias BetPeak.Sports
  alias BetPeak.Sports.Sport

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(sports: Sports.fetch_all())
     |> assign(show_sport_modal: false)
     |> assign(modal_operation: "")
     |> assign(selected_sport: %{})
     |> assign(form: nil)}
  end

  @impl true
  def handle_event(
        "open_sport_modal",
        %{"operation" => operation, "sport_id" => sport_id},
        socket
      ) do
    case operation do
      "add" ->
        changeset = Sports.change_sport_creation(%Sport{}, %{}, validate_unique: false)

        {
          :noreply,
          socket
          |> assign(show_sport_modal: true)
          |> assign(modal_operation: operation)
          |> assign_form(changeset)
        }

      "edit" ->
        sport = Enum.find(socket.assigns.sports, &(&1.id == String.to_integer(sport_id)))
        changeset = Sports.change_sport_creation(sport, %{}, validate_unique: false)

        {
          :noreply,
          socket
          |> assign(selected_sport: sport)
          |> assign(show_sport_modal: true)
          |> assign(modal_operation: operation)
          |> assign_form(Map.put(changeset, :action, :validate))
        }

      "delete" ->
        sport = Enum.find(socket.assigns.sports, &(&1.id == String.to_integer(sport_id)))

        {
          :noreply,
          socket
          |> assign(show_sport_modal: true)
          |> assign(selected_sport: sport)
          |> assign(modal_operation: operation)
        }
    end
  end

  @impl true
  def handle_event("close_sport_modal", _params, socket) do
    {
      :noreply,
      socket
      |> assign(show_sport_modal: false)
      |> assign(modal_operation: "")
      |> assign(selected_sport: %{})
    }
  end

  @impl true
  def handle_event("save_sport", %{"sport" => sport_params}, socket) do
    new_sport_params = Map.put(sport_params, "user_id", socket.assigns.current_scope.user.id)

    case Sports.save_sport(new_sport_params) do
      {:ok, _sport} ->
        {:noreply,
         socket
         |> assign(sports: Sports.fetch_all())
         |> put_flash(:info, "Successfully created the sport")
         |> assign(show_sport_modal: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("update_sport", %{"sport" => sport_params}, socket) do
    new_sport_params = Map.put(sport_params, "user_id", socket.assigns.current_scope.user.id)

    case Sports.update_sport(socket.assigns.selected_sport, new_sport_params) do
      {:ok, _sport} ->
        {:noreply,
         socket
         |> assign(sports: Sports.fetch_all())
         |> put_flash(:info, "Successfully updated the sport")
         |> assign(show_sport_modal: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("delete_sport", _params, socket) do
    case Sports.delete_sport(socket.assigns.selected_sport) do
      {:ok, _sport} ->
        {:noreply,
         socket
         |> assign(sports: Sports.fetch_all())
         |> put_flash(:info, "Successfully deleted the sport")
         |> assign(show_sport_modal: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> put_flash(:info, "Oops! Something went wrong while deleting the sport.")
         |> assign(show_sport_modal: false)}
    end
  end

  @impl true
  def handle_event("validate_sport_form", %{"sport" => sport_params}, socket) do
    new_sport_params = Map.put(sport_params, "user_id", socket.assigns.current_scope.user.id)

    sport =
      if socket.assigns.modal_operation == "edit" do
        socket.assigns.selected_sport
      else
        %Sport{}
      end

    changeset = Sports.change_sport_creation(sport, new_sport_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "sport")
    assign(socket, form: form)
  end

  def sport_modal(assigns) do
    ~H"""
    <dialog
      id="sport-modal"
      class="modal bg-[#161616]/55 backdrop-blur-sm"
      open={@show_sport_modal}
      aria-labelledby="sport-modal-title"
      phx-window-keydown="close_sport_modal"
      phx-key="escape"
    >
      <div class="modal-box max-h-[90vh] max-w-3xl overflow-y-auto rounded-lg bg-[#f8f6f0] p-0 text-[#161616] shadow-2xl">
        <button
          id="close-sport-modal"
          type="button"
          class="absolute right-4 top-4 rounded-2xl z-10 grid size-9 cursor-pointer place-items-center bg-black/5 text-[#161616]/55 transition hover:bg-black/10 hover:text-[#161616]"
          phx-click="close_sport_modal"
          aria-label="Close sport details"
        >
          <.icon name="hero-x-mark" class="size-5" />
        </button>

        <div>
          <header class="flex items-center gap-4 border-b border-[#ded9ce] px-6 py-6 sm:px-8">
            <div class="min-w-0 pr-10">
              <div class="flex flex-wrap items-center gap-2">
                <h2 id="sport-modal-title" class="truncate text-xl font-extrabold">
                  <span :if={@modal_operation == "add"}>Add New Sport</span>
                  <span :if={@modal_operation == "edit" or @modal_operation == "delete"}>
                    {"Sport: #{@selected_sport.name}"}
                  </span>
                </h2>
              </div>
            </div>
          </header>

          <div :if={@modal_operation == "add" or @modal_operation == "edit"} class="p-6 sm:p-8">
            <div class="mb-6">
              <p class="mt-1 text-sm text-[#161616]/50">
                {if(@modal_operation == "add",
                  do: "Fill in all fields to save a new sport!",
                  else: "Update the sport!"
                )}
              </p>
            </div>
            <.form
              :if={@form}
              for={@form}
              id="sport_form"
              phx-change="validate_sport_form"
              phx-submit={if(@modal_operation == "add", do: "save_sport", else: "update_sport")}
              class="space-y-6"
            >
              <div class="sm:col-span-2">
                <.input
                  field={@form[:name]}
                  type="text"
                  label="Name"
                  autocomplete="sport-name"
                  placeholder="e.g. Football"
                  spellcheck="true"
                  required
                  class="h-12 rounded-2xl w-full border border-[#d7d2c7] bg-white px-4 text-[#161616] outline-none transition placeholder:text-[#161616]/30 focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                  error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                />
              </div>
              <div>
                <.input
                  field={@form[:description]}
                  type="textarea"
                  label="Description"
                  autocomplete="sport-description"
                  placeholder="e.g. Write 1 or 2 sentences about the sport"
                  spellcheck="true"
                  required
                  class="h-12 textarea rounded-2xl w-full border border-[#d7d2c7] bg-white px-4 text-[#161616] outline-none transition placeholder:text-[#161616]/30 focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                  error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                />
              </div>

              <fieldset
                id="sport-active-group"
                class="fieldset mb-2 w-full"
                aria-labelledby="sport-active-label"
              >
                <span id="sport-active-label" class="label mb-1">Is Active</span>
                <div class="grid grid-cols-2 gap-1 rounded-2xl border border-[#d7d2c7] bg-white p-1 transition focus-within:border-[#b28708] focus-within:ring-2 focus-within:ring-[#f4bf25]/20">
                  <label
                    for="sport-active-true"
                    class="flex min-h-10 cursor-pointer items-center justify-center gap-2 rounded-xl px-4 text-sm font-semibold text-[#161616]/60 transition hover:bg-[#f6f4ee] has-[:checked]:bg-[#161616] has-[:checked]:text-white"
                  >
                    <input
                      id="sport-active-true"
                      type="radio"
                      name={@form[:active].name}
                      value="true"
                      checked={to_string(@form[:active].value) == "true"}
                      class="radio radio-xs border-current text-[#f4bf25] checked:border-[#f4bf25] checked:bg-[#f4bf25]"
                    /> True
                  </label>
                  <label
                    for="sport-active-false"
                    class="flex min-h-10 cursor-pointer items-center justify-center gap-2 rounded-xl px-4 text-sm font-semibold text-[#161616]/60 transition hover:bg-[#f6f4ee] has-[:checked]:bg-[#161616] has-[:checked]:text-white"
                  >
                    <input
                      id="sport-active-false"
                      type="radio"
                      name={@form[:active].name}
                      value="false"
                      checked={to_string(@form[:active].value) == "false"}
                      class="radio radio-xs border-current text-[#f4bf25] checked:border-[#f4bf25] checked:bg-[#f4bf25]"
                    /> False
                  </label>
                </div>
              </fieldset>

              <div class="flex justify-end border-t border-[#ded9ce] pt-5">
                <.button
                  phx-disable-with="Saving sport ..."
                  class="group rounded-2xl flex h-11 items-center justify-center gap-2 bg-[#161616] px-6 text-sm font-bold text-white transition hover:bg-[#735700] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#b28708]"
                >
                  Save sport
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
                  <h3 class="font-bold text-red-950">Delete this sport?</h3>
                  <p class="font-extrabold italic mt-2 mb-2">{@selected_sport.name}</p>
                  <p class="mt-1 text-sm leading-6 text-red-900/65">
                    This permanently removes the sport and all associated data.
                  </p>
                </div>
              </div>
            </div>
            <div class="flex justify-end border-t border-[#ded9ce] pt-5">
              <.button
                phx-disable-with="Deleting sport..."
                class="mt-5 rounded-2xl flex h-11 items-center justify-center gap-2 bg-red-600 px-6 text-sm font-bold text-white transition hover:bg-red-700 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600"
                phx-click="delete_sport"
              >
                <.icon name="hero-trash" class="size-4" /> Delete sport
              </.button>
            </div>
          </div>
        </div>
      </div>
      <button class="modal-backdrop" phx-click="close_sport_modal" aria-label="Close sport details">
        close
      </button>
    </dialog>
    """
  end
end
