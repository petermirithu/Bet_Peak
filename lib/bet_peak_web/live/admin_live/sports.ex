defmodule BetPeakWeb.AdminLive.Sports do
  use BetPeakWeb, :live_view

  alias BetPeakWeb.Helpers
  alias BetPeak.Sports
  alias BetPeak.Sports.Sport
  alias BetPeak.Authorization

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(sports: Sports.fetch_all(socket.assigns.current_scope))
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

    case Sports.save_sport(socket.assigns.current_scope, new_sport_params) do
      {:ok, _sport} ->
        {:noreply,
         socket
         |> assign(sports: Sports.fetch_all(socket.assigns.current_scope))
         |> put_flash(:info, "Successfully created the sport")
         |> assign(show_sport_modal: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        render_default_form_error(socket, changeset, "adding")

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are not authorized to add a sport!")}

      {:error, _} ->
        render_default_form_error(socket, nil, "adding")
    end
  end

  @impl true
  def handle_event("update_sport", %{"sport" => sport_params}, socket) do
    new_sport_params = Map.put(sport_params, "user_id", socket.assigns.current_scope.user.id)

    case Sports.update_sport(
           socket.assigns.current_scope,
           socket.assigns.selected_sport,
           new_sport_params
         ) do
      {:ok, _sport} ->
        {:noreply,
         socket
         |> assign(sports: Sports.fetch_all(socket.assigns.current_scope))
         |> put_flash(:info, "Successfully updated the sport")
         |> assign(show_sport_modal: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        render_default_form_error(socket, changeset, "updating")

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are not authorized to update a sport!")}

      {:error, _} ->
        render_default_form_error(socket, nil, "updating")
    end
  end

  @impl true
  def handle_event("delete_sport", _params, socket) do
    case Sports.delete_sport(socket.assigns.current_scope, socket.assigns.selected_sport) do
      {:ok, _sport} ->
        {:noreply,
         socket
         |> assign(sports: Sports.fetch_all(socket.assigns.current_scope))
         |> put_flash(:info, "Successfully deleted the sport")
         |> assign(show_sport_modal: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        render_default_form_error(socket, changeset, "deleting")

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are not authorized to delete a sport!")}

      {:error, _} ->
        render_default_form_error(socket, nil, "deleting")
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

  defp render_default_form_error(socket, changeset, operation) do
    case changeset do
      nil ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "Oops! Something went wrong while #{operation} the sport. Try again later."
         )
         |> assign(show_sport_modal: false)}

      _ ->
        {:noreply,
         socket
         |> assign_form(changeset)
         |> put_flash(
           :error,
           "Oops! Something went wrong while #{operation} the sport. Try again later."
         )
         |> assign(show_sport_modal: false)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "sport")
    assign(socket, form: form)
  end

  def sport_modal(assigns) do
    ~H"""
    <dialog
      id="sport-modal"
      open={@show_sport_modal}
      aria-labelledby="sport-modal-title"
      phx-window-keydown="close_sport_modal"
      phx-key="escape"
      class={[
        "fixed inset-0 z-50 m-0 hidden h-screen max-h-none w-screen max-w-none",
        "items-center justify-center overflow-y-auto border-0 bg-transparent p-4",
        "open:flex"
      ]}
    >
      <.button
        id="sport-modal-backdrop"
        type="button"
        phx-click="close_sport_modal"
        aria-label="Close sport dialog"
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
          id="close-sport-modal"
          type="button"
          phx-click="close_sport_modal"
          aria-label="Close sport dialog"
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

        <div :if={@show_sport_modal}>
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
                <.icon name="hero-trophy" class="size-6" />
              </span>

              <div class="min-w-0">
                <p class="mb-1 text-xs font-bold text-[#947000]">Sports management</p>
                <h2 id="sport-modal-title" class="truncate text-xl font-extrabold sm:text-2xl">
                  <%= case @modal_operation do %>
                    <% "add" -> %>
                      Add new sport
                    <% "edit" -> %>
                      Edit {@selected_sport.name}
                    <% "delete" -> %>
                      Delete {@selected_sport.name}
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
                  do: "Add a sport that can be used to organize teams, events, and betting markets.",
                  else: "Update this sport's display information and availability."
                )}
              </p>
            </div>

            <.form
              :if={@form}
              for={@form}
              id="sport-form"
              phx-change="validate_sport_form"
              phx-submit={if(@modal_operation == "add", do: "save_sport", else: "update_sport")}
              class="space-y-7"
            >
              <div class="rounded-2xl border border-[#ded9ce] bg-white p-5 shadow-sm sm:p-6">
                <div class="mb-5 flex items-start gap-3">
                  <span class="grid size-10 shrink-0 place-items-center rounded-xl bg-[#fff1b8] text-[#806000]">
                    <.icon name="hero-trophy" class="size-5" />
                  </span>
                  <div>
                    <h3 class="font-extrabold text-[#161616]">Sport information</h3>
                    <p class="mt-1 text-sm leading-5 text-[#161616]/50">
                      Use a clear name and a short description for administrators and bettors.
                    </p>
                  </div>
                </div>

                <.input
                  field={@form[:name]}
                  type="text"
                  label="Sport name"
                  autocomplete="sport-name"
                  placeholder="e.g. Football"
                  spellcheck="true"
                  required
                  class="h-12 w-full rounded-2xl border border-[#d7d2c7] bg-white px-4 text-[#161616] shadow-sm outline-none transition placeholder:text-[#161616]/30 hover:border-[#b8ae9c] focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                  error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                />

                <.input
                  field={@form[:description]}
                  type="textarea"
                  label="Description"
                  autocomplete="sport-description"
                  placeholder="Write one or two sentences about the sport"
                  spellcheck="true"
                  required
                  class="min-h-32 w-full resize-y rounded-2xl border border-[#d7d2c7] bg-white px-4 py-3 text-[#161616] shadow-sm outline-none transition placeholder:text-[#161616]/30 hover:border-[#b8ae9c] focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                  error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                />

                <fieldset
                  id="sport-active-group"
                  class="mt-5 w-full"
                  aria-labelledby="sport-active-label"
                >
                  <legend id="sport-active-label" class="mb-2 text-sm font-semibold text-[#161616]">
                    Availability
                  </legend>
                  <div class="grid grid-cols-2 gap-1 rounded-2xl border border-[#d7d2c7] bg-[#f2efe7] p-1 transition focus-within:border-[#b28708] focus-within:ring-2 focus-within:ring-[#f4bf25]/20">
                    <label
                      for="sport-active-true"
                      class="flex min-h-10 cursor-pointer items-center justify-center gap-2 rounded-xl px-4 text-sm font-semibold text-[#161616]/60 transition hover:bg-white/70 has-[:checked]:bg-[#161616] has-[:checked]:text-white has-[:checked]:shadow-sm"
                    >
                      <input
                        id="sport-active-true"
                        type="radio"
                        name={@form[:active].name}
                        value="true"
                        checked={to_string(@form[:active].value) == "true"}
                        class="sr-only"
                      />
                      <.icon name="hero-check-circle" class="size-4" /> Active
                    </label>
                    <label
                      for="sport-active-false"
                      class="flex min-h-10 cursor-pointer items-center justify-center gap-2 rounded-xl px-4 text-sm font-semibold text-[#161616]/60 transition hover:bg-white/70 has-[:checked]:bg-[#161616] has-[:checked]:text-white has-[:checked]:shadow-sm"
                    >
                      <input
                        id="sport-active-false"
                        type="radio"
                        name={@form[:active].name}
                        value="false"
                        checked={to_string(@form[:active].value) == "false"}
                        class="sr-only"
                      />
                      <.icon name="hero-pause-circle" class="size-4" /> Inactive
                    </label>
                  </div>
                </fieldset>
              </div>

              <footer class="flex flex-col-reverse gap-3 border-t border-[#ded9ce] pt-6 sm:flex-row sm:justify-end">
                <.button
                  id="cancel-sport-form"
                  type="button"
                  phx-click="close_sport_modal"
                  class="inline-flex h-11 items-center justify-center rounded-xl border border-[#d7d2c7] bg-white px-5 text-sm font-bold text-[#161616] transition hover:bg-[#f2efe7] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#161616]/15"
                >
                  Cancel
                </.button>
                <.button
                  id="submit-sport-form"
                  type="submit"
                  phx-disable-with="Saving sport..."
                  class="group inline-flex h-11 items-center justify-center gap-2 rounded-xl bg-[#161616] px-6 text-sm font-bold text-white shadow-sm transition duration-200 hover:-translate-y-0.5 hover:bg-[#735700] hover:shadow-md focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#b28708]/40 disabled:cursor-wait disabled:opacity-60"
                >
                  {if(@modal_operation == "add", do: "Create sport", else: "Save changes")}
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
                  <h3 class="font-extrabold text-red-950">Delete this sport?</h3>
                  <p class="mt-1 text-sm leading-6 text-red-900/65">
                    This permanently removes <strong>{@selected_sport.name}</strong>
                    and may affect associated data.
                  </p>
                </div>
              </div>
            </div>

            <div class="mt-6 flex flex-col-reverse gap-3 border-t border-[#ded9ce] pt-6 sm:flex-row sm:justify-end">
              <.button
                id="cancel-delete-sport"
                type="button"
                phx-click="close_sport_modal"
                class="inline-flex h-11 items-center justify-center rounded-xl border border-[#d7d2c7] bg-white px-5 text-sm font-bold text-[#161616] transition hover:bg-[#f2efe7]"
              >
                Cancel
              </.button>
              <.button
                id="confirm-delete-sport"
                type="button"
                phx-disable-with="Deleting sport..."
                phx-click="delete_sport"
                class="inline-flex h-11 items-center justify-center gap-2 rounded-xl bg-red-600 px-6 text-sm font-bold text-white shadow-sm transition hover:-translate-y-0.5 hover:bg-red-700 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-red-600/35"
              >
                <.icon name="hero-trash" class="size-4" /> Delete sport
              </.button>
            </div>
          </div>
        </div>
      </div>
    </dialog>
    """
  end
end
