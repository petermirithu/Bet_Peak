defmodule BetPeakWeb.AdminLive.Teams do
  use BetPeakWeb, :live_view

  alias BetPeakWeb.Helpers
  alias BetPeak.Teams
  alias BetPeak.Teams.Team
  alias BetPeak.Sports

  @impl true
  def mount(_params, _session, socket) do
    sports =
      Sports.fetch_all_active(socket.assigns.current_scope)
      |> Enum.map(&{&1.name, &1.id})

    {
      :ok,
      socket
      |> assign(sports: sports)
      |> assign(teams: Teams.fetch_all(socket.assigns.current_scope))
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

    case Teams.save_team(socket.assigns.current_scope, new_team_params) do
      {:ok, _team} ->
        {:noreply,
         socket
         |> assign(teams: Teams.fetch_all(socket.assigns.current_scope))
         |> put_flash(:info, "Successfully created the team")
         |> assign(show_team_modal: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign_form(changeset)}

      {:error, :unauthorized} ->
        {:noreply, socket |> put_flash(:error, "You not authorized to create a team!")}

      {:error, _} ->
        render_default_form_error(socket, nil, "adding")
    end
  end

  @impl true
  def handle_event("update_team", %{"team" => team_params}, socket) do
    new_team_params = Map.put(team_params, "user_id", socket.assigns.current_scope.user.id)

    case Teams.update_team(
           socket.assigns.current_scope,
           socket.assigns.selected_team,
           new_team_params
         ) do
      {:ok, _team} ->
        {:noreply,
         socket
         |> assign(teams: Teams.fetch_all(socket.assigns.current_scope))
         |> put_flash(:info, "Successfully updated the team")
         |> assign(show_team_modal: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign_form(changeset)}

      {:error, :unauthorized} ->
        {:noreply, socket |> put_flash(:error, "You not authorized to update a team!")}

      {:error, _} ->
        render_default_form_error(socket, nil, "updating")
    end
  end

  @impl true
  def handle_event("delete_team", _params, socket) do
    case Teams.delete_team(socket.assigns.current_scope, socket.assigns.selected_team) do
      {:ok, _team} ->
        {:noreply,
         socket
         |> assign(teams: Teams.fetch_all(socket.assigns.current_scope))
         |> put_flash(:info, "Successfully delete the team")
         |> assign(show_team_modal: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        render_default_form_error(socket, changeset, "deleting")

      {:error, :unauthorized} ->
        {:noreply, socket |> put_flash(:error, "You not authorized to delete a team!")}

      {:error, _} ->
        render_default_form_error(socket, nil, "deleting")
    end
  end

  @impl true
  def handle_event("validate_team_form", %{"team" => team_params}, socket) do
    new_team_params = Map.put(team_params, "user_id", socket.assigns.current_scope.user.id)

    team =
      if socket.assigns.modal_operation == "edit" do
        socket.assigns.selected_team
      else
        %Team{}
      end

    changeset = Teams.change_team_creation(team, new_team_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp render_default_form_error(socket, changeset, operation) do
    case changeset do
      nil ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "Oops! Something went wrong while #{operation} the team. Try again later."
         )
         |> assign(show_team_modal: false)}

      _ ->
        {:noreply,
         socket
         |> assign_form(changeset)
         |> put_flash(
           :error,
           "Oops! Something went wrong while #{operation} the team. Try again later."
         )
         |> assign(show_team_modal: false)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "team")
    assign(socket, form: form)
  end

  def team_modal(assigns) do
    ~H"""
    <dialog
      id="team-modal"
      open={@show_team_modal}
      aria-labelledby="team-modal-title"
      phx-window-keydown="close_team_modal"
      phx-key="escape"
      class={[
        "fixed inset-0 z-50 m-0 hidden h-screen max-h-none w-screen max-w-none",
        "items-center justify-center overflow-y-auto border-0 bg-transparent p-4",
        "open:flex"
      ]}
    >
      <.button
        id="team-modal-backdrop"
        type="button"
        phx-click="close_team_modal"
        aria-label="Close team dialog"
        class={[
          "absolute inset-0 cursor-default bg-[#161616]/60 backdrop-blur-sm",
          "transition-opacity"
        ]}
      >
        <span class="sr-only">Close</span>
      </.button>

      <div class={[
        "relative z-10 w-full max-w-2xl overflow-hidden rounded-3xl",
        "border border-white/40 bg-[#f8f6f0] text-[#161616]",
        "shadow-[0_30px_90px_rgba(0,0,0,0.35)]"
      ]}>
        <.button
          id="close-team-modal"
          type="button"
          phx-click="close_team_modal"
          aria-label="Close team dialog"
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

        <div :if={@show_team_modal}>
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
                <.icon name="hero-user-group" class="size-6" />
              </span>

              <div class="min-w-0">
                <p class="mb-1 text-xs font-bold text-[#947000]">Teams management</p>
                <h2 id="team-modal-title" class="truncate text-xl font-extrabold sm:text-2xl">
                  <%= case @modal_operation do %>
                    <% "add" -> %>
                      Add new team
                    <% "edit" -> %>
                      Edit {@selected_team.name}
                    <% "delete" -> %>
                      Delete {@selected_team.name}
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
                  do: "Add a team and connect it to the sport it competes in.",
                  else: "Update this team's identity, sport, and public description."
                )}
              </p>
            </div>

            <.form
              :if={@form}
              for={@form}
              id="team-form"
              phx-change="validate_team_form"
              phx-submit={if(@modal_operation == "add", do: "save_team", else: "update_team")}
              class="space-y-7"
            >
              <div class="rounded-2xl border border-[#ded9ce] bg-white p-5 shadow-sm sm:p-6">
                <div class="mb-5 flex items-start gap-3">
                  <span class="grid size-10 shrink-0 place-items-center rounded-xl bg-[#fff1b8] text-[#806000]">
                    <.icon name="hero-user-group" class="size-5" />
                  </span>
                  <div>
                    <h3 class="font-extrabold text-[#161616]">Team information</h3>
                    <p class="mt-1 text-sm leading-5 text-[#161616]/50">
                      Add the identifiers used across fixtures, markets, and results.
                    </p>
                  </div>
                </div>

                <div class="grid gap-x-4 sm:grid-cols-2">
                  <div class="sm:col-span-2">
                    <.input
                      field={@form[:sport_id]}
                      type="select"
                      label="Sport"
                      prompt="Select a sport"
                      options={@sports}
                      required
                      class="h-12 w-full rounded-2xl border border-[#d7d2c7] bg-white px-4 text-[#161616] shadow-sm outline-none transition hover:border-[#b8ae9c] focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                      error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                    />
                  </div>
                  <div>
                    <.input
                      field={@form[:name]}
                      type="text"
                      label="Team name"
                      autocomplete="team-name"
                      placeholder="e.g. Manchester City"
                      spellcheck="false"
                      required
                      class="h-12 w-full rounded-2xl border border-[#d7d2c7] bg-white px-4 text-[#161616] shadow-sm outline-none transition placeholder:text-[#161616]/30 hover:border-[#b8ae9c] focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                      error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                    />
                  </div>
                  <div>
                    <.input
                      field={@form[:short_form]}
                      type="text"
                      label="Short name"
                      autocomplete="team-short-form"
                      placeholder="e.g. MCI"
                      spellcheck="false"
                      required
                      class="h-12 w-full rounded-2xl border border-[#d7d2c7] bg-white px-4 text-[#161616] shadow-sm outline-none transition placeholder:text-[#161616]/30 hover:border-[#b8ae9c] focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                      error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                    />
                  </div>
                  <div class="sm:col-span-2">
                    <.input
                      field={@form[:about]}
                      type="textarea"
                      label="About the team"
                      autocomplete="team-description"
                      placeholder="Write one or two sentences about the team"
                      spellcheck="true"
                      required
                      class="min-h-32 w-full resize-y rounded-2xl border border-[#d7d2c7] bg-white px-4 py-3 text-[#161616] shadow-sm outline-none transition placeholder:text-[#161616]/30 hover:border-[#b8ae9c] focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                      error_class="border-[#b42318] focus:border-[#b42318] focus:ring-[#b42318]/15"
                    />
                  </div>
                </div>
              </div>

              <footer class="flex flex-col-reverse gap-3 border-t border-[#ded9ce] pt-6 sm:flex-row sm:justify-end">
                <.button
                  id="cancel-team-form"
                  type="button"
                  phx-click="close_team_modal"
                  class="inline-flex h-11 items-center justify-center rounded-xl border border-[#d7d2c7] bg-white px-5 text-sm font-bold text-[#161616] transition hover:bg-[#f2efe7] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#161616]/15"
                >
                  Cancel
                </.button>
                <.button
                  id="submit-team-form"
                  type="submit"
                  phx-disable-with="Saving team..."
                  class="group inline-flex h-11 items-center justify-center gap-2 rounded-xl bg-[#161616] px-6 text-sm font-bold text-white shadow-sm transition duration-200 hover:-translate-y-0.5 hover:bg-[#735700] hover:shadow-md focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#b28708]/40 disabled:cursor-wait disabled:opacity-60"
                >
                  {if(@modal_operation == "add", do: "Create team", else: "Save changes")}
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
                  <h3 class="font-extrabold text-red-950">Delete this team?</h3>
                  <p class="mt-1 text-sm leading-6 text-red-900/65">
                    This permanently removes <strong>{@selected_team.name}</strong>
                    and may affect associated data.
                  </p>
                </div>
              </div>
            </div>

            <div class="mt-6 flex flex-col-reverse gap-3 border-t border-[#ded9ce] pt-6 sm:flex-row sm:justify-end">
              <.button
                id="cancel-delete-team"
                type="button"
                phx-click="close_team_modal"
                class="inline-flex h-11 items-center justify-center rounded-xl border border-[#d7d2c7] bg-white px-5 text-sm font-bold text-[#161616] transition hover:bg-[#f2efe7]"
              >
                Cancel
              </.button>
              <.button
                id="confirm-delete-team"
                type="button"
                phx-disable-with="Deleting team..."
                phx-click="delete_team"
                phx-value-team_id={@selected_team.id}
                class="inline-flex h-11 items-center justify-center gap-2 rounded-xl bg-red-600 px-6 text-sm font-bold text-white shadow-sm transition hover:-translate-y-0.5 hover:bg-red-700 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-red-600/35"
              >
                <.icon name="hero-trash" class="size-4" /> Delete team
              </.button>
            </div>
          </div>
        </div>
      </div>
    </dialog>
    """
  end
end
