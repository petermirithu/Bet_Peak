defmodule BetPeakWeb.AdminLive.Teams do
  use BetPeakWeb, :live_view

  alias BetPeakWeb.Helpers
  alias BetPeak.Teams
  alias BetPeak.Teams.Team
  alias BetPeak.Sports

  @impl true
  def mount(_params, _session, socket) do
    sports =
      Sports.fetch_all()
      |> Enum.map(&{String.to_atom("#{&1.name}"), &1.id})

    {
      :ok,
      socket
      |> assign(sports: sports)
      |> assign(teams: Teams.fetch_all())
      |> assign(show_team_modal: false)
      |> assign(modal_operation: "")
      |> assign(selected_team: %{})
      |> assign(form: nil)
    }
  end

  @impl true
  def handle_event(
        "open_team_modal",
        %{"operation" => operation, "team_id" => team_id},
        socket
      ) do
    case operation do
      "add" ->
        changeset = Teams.change_team_creation(%Team{}, %{}, validate_unique: false)

        {
          :noreply,
          socket
          |> assign(show_team_modal: true)
          |> assign(modal_operation: operation)
          |> assign_form(changeset)
        }

      "edit" ->
        team = Enum.find(socket.assigns.teams, &(&1.id == String.to_integer(team_id)))
        changeset = Teams.change_team_creation(team, %{}, validate_unique: false)

        {
          :noreply,
          socket
          |> assign(selected_team: team)
          |> assign(show_team_modal: true)
          |> assign(modal_operation: operation)
          |> assign_form(Map.put(changeset, :action, :validate))
        }

      "delete" ->
        team = Enum.find(socket.assigns.teams, &(&1.id == String.to_integer(team_id)))

        {
          :noreply,
          socket
          |> assign(show_team_modal: true)
          |> assign(selected_team: team)
          |> assign(modal_operation: operation)
        }
    end
  end

  @impl true
  def handle_event("close_team_modal", _params, socket) do
    {
      :noreply,
      socket
      |> assign(show_team_modal: false)
      |> assign(modal_operation: "")
      |> assign(selected_team: %{})
    }
  end

  @impl true
  def handle_event("save_team", %{"team" => team_params}, socket) do
    new_team_params = Map.put(team_params, "user_id", socket.assigns.current_scope.user.id)

    case Teams.save_team(new_team_params) do
      {:ok, _team} ->
        {:noreply,
         socket
         |> assign(teams: Teams.fetch_all())
         |> put_flash(:info, "Successfully created the team")
         |> assign(show_team_modal: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("update_team", %{"team" => team_params}, socket) do
    new_team_params = Map.put(team_params, "user_id", socket.assigns.current_scope.user.id)

    case Teams.update_team(socket.assigns.selected_team, new_team_params) do
      {:ok, _team} ->
        {:noreply,
         socket
         |> assign(teams: Teams.fetch_all())
         |> put_flash(:info, "Successfully updated the team")
         |> assign(show_team_modal: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("delete_team", _params, socket) do
    case Teams.delete_team(socket.assigns.selected_team) do
      {:ok, _team} ->
        {:noreply,
         socket
         |> assign(teams: Teams.fetch_all())
         |> put_flash(:info, "Successfully delete the team")
         |> assign(show_team_modal: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> put_flash(:info, "Oops! Something went wrong while deleting the team.")
         |> assign(show_team_modal: false)}
    end
  end

  @impl true
  def handle_event("validate_team_form", %{"team" => team_params}, socket) do
    new_team_params = Map.put(team_params, "user_id", socket.assigns.current_scope.user.id)
    changeset = Teams.change_team_creation(%Team{}, new_team_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "team")
    assign(socket, form: form)
  end

  def team_modal(assigns) do
    ~H"""
    <dialog
      id="team-modal"
      class="modal bg-[#161616]/55 backdrop-blur-sm"
      open={@show_team_modal}
      aria-labelledby="team-modal-title"
      phx-window-keydown="close_team_modal"
      phx-key="escape"
    >
      <div class="modal-box max-h-[90vh] max-w-3xl overflow-y-auto rounded-lg bg-[#f8f6f0] p-0 text-[#161616] shadow-2xl">
        <button
          id="close-team-modal"
          type="button"
          class="absolute right-4 top-4 rounded-2xl z-10 grid size-9 cursor-pointer place-items-center bg-black/5 text-[#161616]/55 transition hover:bg-black/10 hover:text-[#161616]"
          phx-click="close_team_modal"
          aria-label="Close team details"
        >
          <.icon name="hero-x-mark" class="size-5" />
        </button>

        <div>
          <header class="flex items-center gap-4 border-b border-[#ded9ce] px-6 py-6 sm:px-8">
            <div class="min-w-0 pr-10">
              <div class="flex flex-wrap items-center gap-2">
                <h2 id="team-modal-title" class="truncate text-xl font-extrabold">
                  <span :if={@modal_operation == "add"}>Add New Team</span>
                  <span :if={@modal_operation == "edit" or @modal_operation == "delete"}>
                    {"Team: #{@selected_team.name}"}
                  </span>
                </h2>
              </div>
            </div>
          </header>

          <div :if={@modal_operation == "add" or @modal_operation == "edit"} class="p-6 sm:p-8">
            <div class="mb-6">
              <p class="mt-1 text-sm text-[#161616]/50">
                {if(@modal_operation == "add",
                  do: "Fill in all fields to save a new team!",
                  else: "Update the team!"
                )}
              </p>
            </div>
            <.form
              :if={@form}
              for={@form}
              id="team_form"
              phx-change="validate_team_form"
              phx-submit={if(@modal_operation == "add", do: "save_team", else: "update_team")}
              class="grid gap-x-4 sm:grid-cols-2"
            >
              <div class="sm:col-span-2">
                <.input
                  field={@form[:sport_id]}
                  type="select"
                  label="Select Sport"
                  options={@sports}
                  spellcheck="false"
                  required
                  class="h-12 select rounded-2xl w-full border border-[#d7d2c7] bg-white px-4 text-[#161616] outline-none transition placeholder:text-[#161616]/30 focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                  error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                />
              </div>
              <div>
                <.input
                  field={@form[:name]}
                  type="text"
                  label="Name"
                  autocomplete="team-name"
                  placeholder="e.g. Mancity"
                  spellcheck="false"
                  required
                  class="h-12 rounded-2xl w-full border border-[#d7d2c7] bg-white px-4 text-[#161616] outline-none transition placeholder:text-[#161616]/30 focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                  error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                />
              </div>
              <div>
                <.input
                  field={@form[:short_form]}
                  type="text"
                  label="Short Form for Name"
                  autocomplete="team-short-form"
                  placeholder="e.g. MCI"
                  spellcheck="false"
                  required
                  class="h-12 rounded-2xl w-full border border-[#d7d2c7] bg-white px-4 text-[#161616] outline-none transition placeholder:text-[#161616]/30 focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                  error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                />
              </div>
              <div class="sm:col-span-2">
                <.input
                  field={@form[:about]}
                  type="textarea"
                  label="About Team"
                  autocomplete="team-description"
                  placeholder="e.g. Write 1 or 2 sentences about the team"
                  spellcheck="true"
                  required
                  class="h-12 textarea rounded-2xl w-full border border-[#d7d2c7] bg-white px-4 text-[#161616] outline-none transition placeholder:text-[#161616]/30 focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                  error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                />
              </div>

              <div class="flex sm:col-span-2 justify-end border-t border-[#ded9ce] pt-5">
                <.button
                  phx-disable-with="Saving team ..."
                  class="group rounded-2xl flex h-11 items-center justify-center gap-2 bg-[#161616] px-6 text-sm font-bold text-white transition hover:bg-[#735700] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#b28708]"
                >
                  Save team
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
                  <h3 class="font-bold text-red-950">Delete this team?</h3>
                  <p class="font-extrabold italic mt-2 mb-2">{@selected_team.name}</p>
                  <p class="mt-1 text-sm leading-6 text-red-900/65">
                    This permanently removes the team and all associated data.
                  </p>
                </div>
              </div>
            </div>
            <div class="flex justify-end border-t border-[#ded9ce] pt-5">
              <.button
                phx-disable-with="Deleting team..."
                class="mt-5 rounded-2xl flex h-11 items-center justify-center gap-2 bg-red-600 px-6 text-sm font-bold text-white transition hover:bg-red-700 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600"
                phx-click="delete_team"
                phx-value-team_id={@selected_team.id}
              >
                <.icon name="hero-trash" class="size-4" /> Delete team
              </.button>
            </div>
          </div>
        </div>
      </div>
      <button class="modal-backdrop" phx-click="close_team_modal" aria-label="Close team details">
        close
      </button>
    </dialog>
    """
  end
end
