defmodule BetPeakWeb.AdminLive.Users do
  use BetPeakWeb, :live_view

  alias BetPeakWeb.Helpers
  alias BetPeak.Accounts
  alias BetPeak.Bets
  alias BetPeak.Roles
  alias BetPeak.UserRoles
  alias BetPeak.UserRoles.UserRole
  alias BetPeak.Authorization

  @impl true
  def mount(_params, _session, socket) do
    users = Accounts.get_all_users(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(users: users)
     |> assign(roles: Roles.fetch_all(socket.assigns.current_scope))
     |> assign(selected_user: nil)
     |> assign(show_user_modal: false)
     |> assign(modal_operation: "account_info")
     |> assign(changeset: %{})
     |> assign(form: nil)
     |> assign(user_bets_stats: [])}
  end

  @impl true
  def handle_event("select_user", %{"user_id" => user_id}, socket) do
    selected_user = Enum.find(socket.assigns.users, &(&1.id == String.to_integer(user_id)))

    IO.inspect(selected_user)

    {
      :noreply,
      socket
      |> assign(selected_user: selected_user)
      |> assign(show_user_modal: true)
    }
  end

  @impl true
  def handle_event("close_user_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(show_user_modal: false)
     |> assign(modal_operation: "account_info")}
  end

  @impl true
  def handle_event("update_modal_operation", %{"operation" => operation}, socket) do
    case operation do
      "account_bets" ->
        {:noreply,
         socket
         |> assign(modal_operation: operation)
         |> assign(
           user_bets_stats:
             Bets.fetch_admin_user_bets(
               socket.assigns.current_scope,
               socket.assigns.selected_user.id
             )
         )}

      "assign_role" ->
        changeset =
          UserRoles.change_creation(%UserRole{}, %{}, validate_unique: false)

        {:noreply,
         socket
         |> assign(modal_operation: operation)
         |> assign_form(changeset, "user_roles")}

      _ ->
        {:noreply,
         socket
         |> assign(modal_operation: operation)}
    end
  end

  @impl true
  def handle_event("validate_user_access", %{"user_roles" => user_roles}, socket) do
    user_roles_params = Map.put(user_roles, "user_id", socket.assigns.selected_user.id)

    changeset =
      UserRoles.change_creation(
        %UserRole{},
        user_roles_params,
        validate_unique: false
      )

    {:noreply, assign_form(socket, changeset, "user_roles")}
  end

  @impl true
  def handle_event("save_user_access", %{"user_roles" => user_roles}, socket) do
    user_roles_params = Map.put(user_roles, "user_id", socket.assigns.selected_user.id)

    case UserRoles.save(socket.assigns.current_scope, user_roles_params) do
      {:ok, _user_role} ->
        users = Accounts.get_all_users(socket.assigns.current_scope)

        {:noreply,
         socket
         |> assign(show_user_modal: false)
         |> assign(modal_operation: "account_update")
         |> assign(users: users)
         |> assign(selected_user: Enum.find(users, &(&1.id == socket.assigns.selected_user.id)))
         |> put_flash(:info, "User role assigned successfully.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset, "user_roles")}

      {:error, :unauthorized} ->
        {:noreply, socket |> put_flash(:error, "You are not authorized to assign a role!")}

      {:error, _} ->
        render_default_form_error(socket, nil, "updating", "user_roles")
    end
  end

  @impl true
  def handle_event("delete_user_role", %{"user_role_id" => user_role_id}, socket) do
    user_role =
      Enum.find(
        socket.assigns.selected_user.user_roles,
        &(&1.id == String.to_integer(user_role_id))
      )

    case UserRoles.delete(socket.assigns.current_scope, user_role) do
      {:ok, _role} ->
        users = Accounts.get_all_users(socket.assigns.current_scope)

        {:noreply,
         socket
         |> assign(users: users)
         |> assign(selected_user: Enum.find(users, &(&1.id == socket.assigns.selected_user.id)))
         |> assign(modal_operation: "account_update")
         |> put_flash(:info, "Successfully removed the assigned role")}

      {:error, :unauthorized} ->
        {:noreply,
         socket |> put_flash(:error, "You are not authorized to remove an assigned role!")}

      {:error, _} ->
        render_default_form_error(socket, nil, "deleting", "user_role")
    end
  end

  @impl true
  def handle_event("delete_user", _params, socket) do
    case Accounts.delete_user(socket.assigns.current_scope, socket.assigns.selected_user) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> assign(users: Accounts.get_all_users(socket.assigns.current_scope))
         |> put_flash(:info, "Successfully deleted the user")
         |> assign(show_user_modal: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        render_default_form_error(socket, changeset, "deleting", "user")

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are not authorized to delete a user!")}

      {:error, _} ->
        render_default_form_error(socket, nil, "deleting", "user")
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset, table) do
    form = to_form(changeset, as: table)
    assign(socket, form: form)
  end

  defp render_default_form_error(socket, changeset, operation, table) do
    case changeset do
      nil ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "Oops! Something went wrong while #{operation} the #{table}. Try again later."
         )
         |> assign(show_user_modal: false)}

      _ ->
        {:noreply,
         socket
         |> assign_form(changeset, table)
         |> put_flash(
           :error,
           "Oops! Something went wrong while #{operation} the #{table}. Try again later."
         )
         |> assign(show_user_modal: false)}
    end
  end

  attr :selected_user, :any, required: true
  attr :show_user_modal, :boolean, required: true
  attr :modal_operation, :string, required: true
  attr :form, Phoenix.HTML.Form, default: nil
  attr :roles, :list, required: true
  attr :current_scope, :any, required: true
  attr :user_bets_stats, :any, required: true

  def user_modal(assigns) do
    ~H"""
    <dialog
      id="user-modal"
      open={@show_user_modal}
      aria-labelledby="user-modal-title"
      phx-window-keydown="close_user_modal"
      phx-key="escape"
      class={[
        "fixed inset-0 z-50 m-0 hidden h-screen max-h-none w-screen max-w-none",
        "items-center justify-center overflow-y-auto border-0 bg-transparent p-4",
        "open:flex"
      ]}
    >
      <.button
        id="user-modal-backdrop"
        type="button"
        phx-click="close_user_modal"
        aria-label="Close user dialog"
        class={[
          "absolute inset-0 cursor-default bg-[#161616]/60 backdrop-blur-sm",
          "transition-opacity"
        ]}
      >
        <span class={["sr-only"]}>Close</span>
      </.button>

      <div class={[
        "relative z-10 w-full max-w-3xl overflow-hidden rounded-3xl",
        "border border-white/40 bg-[#f8f6f0] text-[#161616]",
        "shadow-[0_30px_90px_rgba(0,0,0,0.35)]"
      ]}>
        <.button
          id="close-user-modal"
          type="button"
          phx-click="close_user_modal"
          aria-label="Close user dialog"
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

        <p
          :if={!@selected_user}
          class={[
            "flex min-h-72 items-center justify-center gap-3 text-sm font-bold text-[#161616]/55"
          ]}
        >
          <.icon name="hero-arrow-path" class={["size-5 animate-spin text-[#947000]"]} /> Loading user
        </p>

        <div :if={@selected_user} class={["max-h-[90vh] overflow-y-auto"]}>
          <header class={[
            "relative overflow-hidden border-b border-[#ded9ce]",
            "bg-gradient-to-br from-white to-[#f4edda] px-6 py-7 sm:px-8"
          ]}>
            <div class={[
              "absolute -right-12 -top-16 size-40 rounded-full",
              "bg-[#f4bf25]/15 blur-2xl"
            ]}>
            </div>

            <div class={["relative flex items-center gap-4 pr-12"]}>
              <div class={[
                "grid size-12 shrink-0 place-items-center rounded-2xl",
                "bg-[#161616] text-sm font-extrabold text-white",
                "shadow-lg shadow-black/10 ring-2 ring-[#f4bf25]/25"
              ]}>
                {Helpers.user_initials(@selected_user)}
              </div>

              <div class={["min-w-0"]}>
                <p class={["mb-1 text-xs font-bold text-[#947000]"]}>User management</p>
                <h2 id="user-modal-title" class={["truncate text-xl font-extrabold sm:text-2xl"]}>
                  {@selected_user.first_name} {@selected_user.last_name}
                </h2>
                <p class={["mt-1 truncate text-sm text-[#161616]/50"]}>
                  {@selected_user.email}
                </p>
              </div>
            </div>
          </header>

          <nav
            id="user-modal-tabs"
            aria-label="User sections"
            class={[
              "grid grid-cols-4 border-b border-[#ded9ce] bg-white px-2",
              "sm:px-8"
            ]}
          >
            <.button
              id="account-info-tab"
              class={[
                "h-12 border-b-2 px-1 text-[11px] font-bold transition sm:px-2 sm:text-sm",
                if(@modal_operation == "account_info",
                  do: "border-[#b28708] text-[#735700]",
                  else: "border-transparent text-[#161616]/45 hover:text-[#161616]"
                )
              ]}
              phx-click="update_modal_operation"
              phx-value-operation="account_info"
            >
              Account Info
            </.button>
            <.button
              id="account-bets-tab"
              class={[
                "h-12 border-b-2 px-1 text-[11px] font-bold transition sm:px-2 sm:text-sm",
                if(@modal_operation == "account_bets",
                  do: "border-[#b28708] text-[#735700]",
                  else: "border-transparent text-[#161616]/45 hover:text-[#161616]"
                )
              ]}
              phx-click="update_modal_operation"
              phx-value-operation="account_bets"
            >
              Bets Placed
            </.button>
            <.button
              id="account-update-tab"
              class={[
                "h-12 border-b-2 px-1 text-[11px] font-bold transition sm:px-2 sm:text-sm",
                if(@modal_operation == "account_update" or @modal_operation == "assign_role",
                  do: "border-[#b28708] text-[#735700]",
                  else: "border-transparent text-[#161616]/45 hover:text-[#161616]"
                )
              ]}
              phx-click="update_modal_operation"
              phx-value-operation="account_update"
            >
              Access Control
            </.button>
            <.button
              id="account-delete-tab"
              class={[
                "h-12 border-b-2 px-1 text-[11px] font-bold transition sm:px-2 sm:text-sm",
                if(@modal_operation == "account_delete",
                  do: "border-red-500 text-red-700",
                  else: "border-transparent text-[#161616]/45 hover:text-red-700"
                )
              ]}
              phx-click="update_modal_operation"
              phx-value-operation="account_delete"
            >
              Delete User
            </.button>
          </nav>

          <div :if={@modal_operation == "account_info"} class="p-6 sm:p-8">
            <dl class="grid gap-x-8 gap-y-5 sm:grid-cols-2">
              <.user_detail label="First name" value={@selected_user.first_name} />
              <.user_detail label="Last name" value={@selected_user.last_name} />
              <.user_detail label="Email" value={@selected_user.email} />
              <.user_detail label="Phone number" value={@selected_user.msisdn} />
              <.user_detail
                label="Verification"
                value={if(@selected_user.confirmed_at, do: "Verified", else: "Pending")}
              />
              <.user_detail label="Joined" value={Helpers.format_date(@selected_user.inserted_at)} />
            </dl>
          </div>

          <div :if={@modal_operation == "account_bets"} class="p-6 sm:p-8">
            <div class="overflow-hidden rounded-2xl border border-[#d8d3c8] bg-white shadow-[0_12px_40px_rgba(22,22,22,0.06)]">
              <div class="overflow-x-auto">
                <table id="bets-table" class="table table-xs">
                  <thead class="bg-[#161616] text-[0.65rem] text-white/60">
                    <tr>
                      <th class="w-12 text-center">#</th>
                      <th>Match</th>
                      <th>Selection</th>
                      <th>Stake Amount</th>
                      <th>Odds at Placement</th>
                      <th>Potential Payout</th>
                      <th>Status</th>
                      <th>Place At</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-[#ece8de]">
                    <tr
                      :for={{bet, index} <- Enum.with_index(@user_bets_stats.bets)}
                      :if={@user_bets_stats.bets != []}
                      id={"bet-row-#{bet.id}"}
                      class="group cursor-pointer transition-colors hover:bg-[#faf7ed]"
                    >
                      <td class="text-center text-xs font-semibold text-[#161616]/35">{index + 1}</td>
                      <td class="whitespace-nowrap">
                        <p class="font-bold text-[#161616]">
                          {bet.game.home_team.short_form} VS {bet.game.away_team.short_form}
                        </p>
                      </td>
                      <td class="text-xs text-[#161616]/65">
                        <span class="badge badge-xs badge-accent badge-outline capitalize">{bet.selection}</span>
                      </td>
                      <td class="whitespace-nowrap text-xs text-[#161616]/65">
                        KES {bet.stake_amount}
                      </td>
                      <td class="whitespace-nowrap text-xs text-[#161616]/65">
                        {bet.odds_at_placement}
                      </td>
                      <td class="whitespace-nowrap text-xs text-[#161616]/65">
                        KES {bet.potential_payout}
                      </td>
                      <td class="whitespace-nowrap text-xs text-[#161616]/65 capitalize">
                        <span
                          :if={bet.status == :pending}
                          class="inline-flex items-center gap-1.5 text-xs font-semibold text-gray-700"
                        >
                          <span class="size-1.5 bg-gray-500 rounded-2xl"></span> {bet.status}
                        </span>

                        <span
                          :if={bet.status == :won}
                          class="inline-flex items-center gap-1.5 text-xs font-semibold text-green-700"
                        >
                          <span class="size-1.5 bg-green-500 rounded-2xl"></span> {bet.status}
                        </span>

                        <span
                          :if={bet.status == :lost}
                          class="inline-flex items-center gap-1.5 text-xs font-semibold text-red-700"
                        >
                          <span class="size-1.5 bg-red-500 rounded-2xl"></span> {bet.status}
                        </span>
                      </td>
                      <td class="whitespace-nowrap text-xs text-[#161616]/50">
                        {Helpers.format_date(bet.inserted_at)}
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <div
                :if={@user_bets_stats.bets == []}
                class="grid min-h-64 place-items-center px-6 text-center"
              >
                <div>
                  <.icon name="hero-ticket" class="mx-auto mb-3 size-8 text-[#161616]/25" />
                  <p class="font-semibold text-[#161616]">No bets found</p>
                </div>
              </div>
            </div>

            <div class="flex justify-end border-t border-[#ded9ce] mt-5">
              <div class="flex mt-5 flex-wrap items-center gap-3 sm:ml-auto sm:justify-end">
                <div class="flex h-10 rounded-2xl items-center gap-2 border border-[#d8d3c8] bg-white px-4 text-sm font-semibold text-[#161616]/65">
                  <.icon name="hero-ticket" class="size-4 text-[#947000]" />
                  {length(@user_bets_stats.bets)} Bets
                </div>

                <div class="flex h-10 rounded-2xl items-center gap-2 border border-[#d8d3c8] bg-white px-4 text-sm font-semibold text-[#161616]/65">
                  <.icon name="hero-arrow-trending-up" class="size-4 text-green-600" />
                  Wins: KES {@user_bets_stats.won}
                </div>

                <div class="flex h-10 rounded-2xl items-center gap-2 border border-[#d8d3c8] bg-white px-4 text-sm font-semibold text-[#161616]/65">
                  <.icon name="hero-arrow-trending-down" class="size-4 text-red-600" />
                  Losses: KES {@user_bets_stats.lost}
                </div>
              </div>
            </div>
          </div>

          <div
            :if={@modal_operation == "account_update" or @modal_operation == "assign_role"}
            class="p-6 sm:p-8"
          >
            <div
              :if={@modal_operation == "account_update"}
              id="user-access-overview"
              class={["space-y-5"]}
            >
              <div class={[
                "flex flex-col gap-4 sm:flex-row sm:items-center",
                "sm:justify-between"
              ]}>
                <div>
                  <div class={["flex items-center gap-2"]}>
                    <span class={[
                      "grid size-9 place-items-center rounded-xl bg-[#fff1b8]",
                      "text-[#806000]"
                    ]}>
                      <.icon name="hero-shield-check" class="size-5" />
                    </span>
                    <h3 class={["font-extrabold text-[#161616]"]}>Assigned roles</h3>
                  </div>
                  <p class={["mt-2 text-sm text-[#161616]/50"]}>
                    Roles determine this user's direct and inherited permissions.
                  </p>
                </div>

                <.button
                  id="assign-user-role-button"
                  type="button"
                  phx-click="update_modal_operation"
                  phx-value-operation="assign_role"
                  disabled={
                    Helpers.is_super_admin(@current_scope) == false and
                      available_roles(@roles, @selected_user) == []
                  }
                  class={[
                    "inline-flex h-11 shrink-0 items-center justify-center gap-2 rounded-xl",
                    "bg-[#161616] px-4 text-sm font-bold text-white shadow-sm",
                    "transition hover:-translate-y-0.5 hover:bg-[#2b2b2b]",
                    "focus-visible:outline-none focus-visible:ring-2",
                    "focus-visible:ring-[#161616]/30",
                    "disabled:cursor-not-allowed disabled:opacity-40 disabled:hover:translate-y-0"
                  ]}
                >
                  <.icon name="hero-plus" class="size-4" /> Assign role
                </.button>
              </div>

              <div class={[
                "overflow-hidden rounded-2xl border border-[#d8d3c8]",
                "bg-white shadow-[0_12px_40px_rgba(22,22,22,0.06)]"
              ]}>
                <div>
                  <table id="user-roles-table" class={["w-full table-fixed text-left"]}>
                    <thead class={[
                      "border-b border-[#ded9ce] bg-[#161616]",
                      "text-[0.68rem] uppercase tracking-wider text-white/60"
                    ]}>
                      <tr>
                        <th class={["w-[32%] px-4 py-3 font-bold sm:px-5"]}>Role</th>
                        <th class={["px-3 py-3 font-bold sm:px-5"]}>Access</th>
                        <th class={["w-14 px-3 py-3 text-right font-bold sm:w-16"]}>
                          <span class={["sr-only"]}>Action</span>
                        </th>
                      </tr>
                    </thead>

                    <tbody id="user-assigned-roles" class={["divide-y divide-[#ece8de]"]}>
                      <tr :if={@selected_user.user_roles == []} id="user-roles-empty">
                        <td colspan="3" class={["px-5 py-12 text-center"]}>
                          <span class={[
                            "mx-auto mb-3 grid size-12 place-items-center rounded-2xl",
                            "bg-[#f2efe7] text-[#161616]/30"
                          ]}>
                            <.icon name="hero-shield-exclamation" class="size-6" />
                          </span>
                          <p class={["font-bold text-[#161616]"]}>No roles assigned</p>
                          <p class={["mt-1 text-sm text-[#161616]/45"]}>
                            Assign a role to grant this user application access.
                          </p>
                        </td>
                      </tr>

                      <tr
                        :for={user_role <- @selected_user.user_roles}
                        id={"user-role-#{user_role.id}"}
                        class={["group align-top transition-colors hover:bg-[#faf7ed]"]}
                      >
                        <td class={["px-4 py-4 sm:px-5"]}>
                          <div class={["flex min-w-0 items-center gap-2.5"]}>
                            <span class={[
                              "grid size-8 shrink-0 place-items-center rounded-lg",
                              "bg-[#161616] text-white"
                            ]}>
                              <.icon name="hero-shield-check" class="size-3.5" />
                            </span>
                            <div class={["min-w-0"]}>
                              <p class={["truncate text-sm font-extrabold text-[#161616]"]}>
                                {user_role.role.name}
                              </p>
                              <p class={["mt-0.5 truncate text-[11px] text-[#161616]/40"]}>
                                {Helpers.format_date(user_role.inserted_at)}
                              </p>
                            </div>
                          </div>
                        </td>

                        <td class={["min-w-0 px-3 py-4 sm:px-5"]}>
                          <div class={["space-y-2"]}>
                            <div class={["flex min-w-0 items-start gap-2"]}>
                              <span class={[
                                "mt-0.5 w-16 shrink-0 text-[10px] font-bold uppercase",
                                "tracking-wide text-[#161616]/35"
                              ]}>
                                Inherits
                              </span>
                              <div class={["flex min-w-0 flex-wrap gap-1"]}>
                                <span
                                  :if={user_role.role.parent_inheritances == []}
                                  class={["text-xs font-medium text-[#161616]/35"]}
                                >
                                  None
                                </span>
                                <span
                                  :for={inheritance <- user_role.role.parent_inheritances}
                                  class={[
                                    "inline-flex min-w-0 max-w-full items-center gap-1 rounded-full",
                                    "border border-[#d8d3c8] bg-[#f8f6f0] px-2 py-0.5",
                                    "text-[11px] font-bold text-[#161616]/65"
                                  ]}
                                >
                                  <.icon name="hero-arrow-turn-down-right" class="size-3 shrink-0" />
                                  <span class={["truncate"]}>{inheritance.parent_role.name}</span>
                                </span>
                              </div>
                            </div>

                            <div class={["flex min-w-0 items-start gap-2"]}>
                              <span class={[
                                "mt-0.5 w-16 shrink-0 text-[10px] font-bold uppercase",
                                "tracking-wide text-[#161616]/35"
                              ]}>
                                Direct
                              </span>
                              <div class={["flex min-w-0 flex-wrap gap-1"]}>
                                <span
                                  :if={user_role.role.role_permissions == []}
                                  class={["text-xs font-medium text-[#161616]/35"]}
                                >
                                  None
                                </span>
                                <span
                                  :for={role_permission <- user_role.role.role_permissions}
                                  class={[
                                    "inline-flex min-w-0 max-w-full items-center gap-1 rounded-full",
                                    "border border-[#ead890] bg-[#fff8dc] px-2 py-0.5",
                                    "text-[11px] font-bold text-[#735700]"
                                  ]}
                                >
                                  <span class={["truncate"]}>
                                    {role_permission.permission.resource.name}
                                  </span>
                                  <span aria-hidden="true" class={["shrink-0 opacity-40"]}>·</span>
                                  <span class={["shrink-0 capitalize"]}>
                                    {role_permission.permission.action}
                                  </span>
                                </span>
                              </div>
                            </div>
                          </div>
                        </td>

                        <td class={["px-3 py-4"]}>
                          <div class={["flex justify-end"]}>
                            <.button
                              id={"delete-user-role-#{user_role.id}"}
                              type="button"
                              phx-click="delete_user_role"
                              phx-value-user_role_id={user_role.id}
                              aria-label={"Remove #{user_role.role.name} from this user"}
                              title="Remove role"
                              disabled={Helpers.is_super_admin(@current_scope) == false}
                              class={[
                                "grid size-8 place-items-center rounded-lg border cursor-pointer",
                                "border-red-200 text-red-600 transition duration-200",
                                "hover:-translate-y-0.5 hover:bg-red-50",
                                "focus-visible:outline-none focus-visible:ring-2",
                                "focus-visible:ring-red-500/30",
                                "disabled:cursor-not-allowed disabled:opacity-40 disabled:hover:translate-y-0"
                              ]}
                            >
                              <.icon name="hero-trash" class="size-3.5" />
                            </.button>
                          </div>
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>

            <div
              :if={@modal_operation == "assign_role"}
              id="assign-user-role-panel"
              class={["space-y-5"]}
            >
              <.form
                :if={@form}
                for={@form}
                id="assign-user-role-form"
                phx-change="validate_user_access"
                phx-submit="save_user_access"
                class={["space-y-6"]}
              >
                <div class={[
                  "overflow-hidden rounded-2xl border border-[#ded9ce]",
                  "bg-white shadow-sm"
                ]}>
                  <div class={[
                    "flex items-start gap-3 border-b border-[#ebe6dc]",
                    "bg-[#fcfaf5] p-5"
                  ]}>
                    <span class={[
                      "grid size-10 shrink-0 place-items-center rounded-xl",
                      "bg-[#fff1b8] text-[#806000]"
                    ]}>
                      <.icon name="hero-shield-plus" class={["size-5"]} />
                    </span>

                    <div>
                      <h3 class={["font-extrabold"]}>Choose a role to assign</h3>
                      <p class={["mt-1 text-sm leading-5 text-[#161616]/50"]}>
                        Only roles not already assigned to this user are shown.
                      </p>
                    </div>
                  </div>

                  <div class={["p-5"]}>
                    <.input
                      field={@form[:role_id]}
                      type="select"
                      label="Role"
                      prompt="Select a role"
                      options={format_roles(available_roles(@roles, @selected_user))}
                      required
                      class={[
                        "h-12 w-full rounded-2xl border border-[#d7d2c7] bg-white px-4",
                        "text-[#161616] shadow-sm outline-none transition duration-200",
                        "hover:border-[#b8ae9c] focus:border-[#b28708]",
                        "focus:ring-2 focus:ring-[#f4bf25]/20"
                      ]}
                      error_class={[
                        "border-[#b42318] focus:border-[#b42318]",
                        "focus:ring-[#b42318]/15"
                      ]}
                    />

                    <p class={["mt-3 flex items-start gap-2 text-xs leading-5 text-[#161616]/45"]}>
                      <.icon name="hero-information-circle" class={["mt-0.5 size-4 shrink-0"]} />
                      The user also receives every permission inherited by the selected role.
                    </p>
                  </div>
                </div>

                <div class={[
                  "flex flex-col-reverse gap-3 border-t border-[#ded9ce] pt-5 sm:flex-row sm:justify-end"
                ]}>
                  <.button
                    id="cancel-assign-user-role"
                    type="button"
                    phx-click="update_modal_operation"
                    phx-value-operation="account_update"
                    class={[
                      "inline-flex h-11 items-center justify-center gap-2 rounded-xl",
                      "border border-[#d7d2c7] bg-white px-5 text-sm font-bold",
                      "text-[#161616] transition hover:bg-[#f2efe7]",
                      "focus-visible:outline-none focus-visible:ring-2",
                      "focus-visible:ring-[#161616]/15"
                    ]}
                  >
                    <.icon name="hero-arrow-left" class={["size-4"]} /> Back
                  </.button>
                  <.button
                    id="submit-assign-user-role"
                    type="submit"
                    phx-disable-with="Assigning role ..."
                    disabled={available_roles(@roles, @selected_user) == []}
                    class={[
                      "group flex h-11 items-center justify-center gap-2 rounded-xl",
                      "bg-[#161616] px-6 text-sm font-bold text-white shadow-sm",
                      "transition hover:-translate-y-0.5 hover:bg-[#735700]",
                      "focus-visible:outline-none focus-visible:ring-2",
                      "focus-visible:ring-[#b28708]/40 disabled:cursor-not-allowed",
                      "disabled:opacity-40 disabled:hover:translate-y-0"
                    ]}
                  >
                    Assign role
                    <.icon
                      name="hero-arrow-right-mini"
                      class="size-4 transition-transform group-hover:translate-x-1"
                    />
                  </.button>
                </div>
              </.form>
            </div>
          </div>

          <div :if={@modal_operation == "account_delete"} class={["p-6 sm:p-8"]}>
            <div class={["rounded-2xl border border-red-200 bg-red-50 p-5"]}>
              <div class={["flex gap-4"]}>
                <span class={[
                  "grid size-10 shrink-0 place-items-center rounded-xl",
                  "bg-red-100 text-red-700"
                ]}>
                  <.icon name="hero-exclamation-triangle" class={["size-5"]} />
                </span>

                <div>
                  <h3 class={["font-extrabold text-red-950"]}>Delete this user?</h3>
                  <p class={["mt-1 text-sm leading-6 text-red-900/65"]}>
                    This permanently removes the account and all associated user data.
                  </p>
                </div>
              </div>
            </div>

            <div class={[
              "mt-6 flex flex-col-reverse gap-3 border-t border-[#ded9ce]",
              "pt-6 sm:flex-row sm:justify-end"
            ]}>
              <.button
                id="cancel-delete-user"
                type="button"
                phx-click="close_user_modal"
                class={[
                  "inline-flex h-11 items-center justify-center rounded-xl",
                  "border border-[#d7d2c7] bg-white px-5 text-sm font-bold",
                  "transition hover:bg-[#f2efe7]"
                ]}
              >
                Cancel
              </.button>

              <.button
                id="confirm-delete-user"
                phx-disable-with="Deleting account..."
                disabled={if(@current_scope.user.id == @selected_user.id, do: true, else: false)}
                phx-click="delete_user"
                class={[
                  "inline-flex h-11 items-center justify-center gap-2 rounded-xl",
                  "bg-red-600 px-6 text-sm font-bold text-white shadow-sm",
                  "transition hover:bg-red-700 focus-visible:outline-none",
                  "focus-visible:ring-2 focus-visible:ring-red-600/30",
                  "disabled:cursor-not-allowed disabled:opacity-40"
                ]}
              >
                <.icon name="hero-trash" class="size-4" /> Delete user
              </.button>
            </div>
          </div>
        </div>
      </div>
    </dialog>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, required: true

  defp user_detail(assigns) do
    ~H"""
    <div class="border-b border-[#ded9ce] pb-3">
      <dt class="text-[0.65rem] font-bold text-[#161616]/40">
        {@label}
      </dt>
      <dd class="mt-1 break-words text-sm font-semibold text-[#161616]">{@value}</dd>
    </div>
    """
  end

  defp available_roles(roles, %{user_roles: user_roles}) when is_list(roles) do
    assigned_role_ids = MapSet.new(user_roles, & &1.role_id)
    Enum.reject(roles, &MapSet.member?(assigned_role_ids, &1.id))
  end

  defp available_roles(_roles, _selected_user), do: []

  defp format_roles(roles) when is_list(roles) do
    roles
    |> Enum.sort_by(fn role -> String.downcase(role.name) end)
    |> Enum.map(fn role -> {role.name, role.id} end)
  end
end
