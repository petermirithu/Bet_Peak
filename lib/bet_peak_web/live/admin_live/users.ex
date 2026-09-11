defmodule BetPeakWeb.AdminLive.Users do
  use BetPeakWeb, :live_view

  alias BetPeakWeb.Helpers
  alias BetPeak.Accounts
  alias BetPeak.Bets

  @impl true
  def mount(_params, _session, socket) do
    users = Accounts.get_all_users()

    {:ok,
     socket
     |> assign(users: users)
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

    {
      :noreply,
      socket
      |> assign(selected_user: selected_user)
      |> assign(show_user_modal: true)
      |> assign_form(Accounts.change_user_access(selected_user))
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
    user_bets_stats =
      if operation == "account_bets" do
        Bets.fetch_admin_user_bets(socket.assigns.selected_user.id)
      else
        []
      end

    {:noreply,
     socket
     |> assign(modal_operation: operation)
     |> assign(user_bets_stats: user_bets_stats)}
  end

  @impl true
  def handle_event("validate_user_access", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.selected_user
      |> Accounts.change_user_access(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save_user_access", %{"user" => user_params}, socket) do
    case Accounts.update_user_access(socket.assigns.selected_user, user_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign_form(Accounts.change_user_access(user))
         |> assign(show_user_modal: false)
         |> assign(modal_operation: "account_info")
         |> assign(users: Accounts.get_all_users())
         |> assign(selected_user: user)
         |> put_flash(:info, "User access updated successfully.")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset, as: :user))
  end

  @impl true
  def handle_event("delete_user", _params, socket) do
    case Accounts.delete_user(socket.assigns.selected_user) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> assign(users: Accounts.get_all_users())
         |> put_flash(:info, "Successfully deleted the user")
         |> assign(show_user_modal: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> put_flash(:info, "Oops! Something went wrong while deleting the user.")
         |> assign(show_user_modal: false)}
    end
  end

  attr :selected_user, :any, required: true
  attr :show_user_modal, :boolean, required: true
  attr :modal_operation, :string, required: true
  attr :form, Phoenix.HTML.Form, default: nil

  def user_modal(assigns) do
    ~H"""
    <dialog
      id="user-modal"
      class="modal bg-[#161616]/55 backdrop-blur-sm"
      open={@show_user_modal}
      aria-labelledby="user-modal-title"
      phx-window-keydown="close_user_modal"
      phx-key="escape"
    >
      <div class="modal-box max-h-[90vh] max-w-3xl overflow-y-auto rounded-lg bg-[#f8f6f0] p-0 text-[#161616] shadow-2xl">
        <button
          id="close-user-modal"
          type="button"
          class="absolute right-4 top-4 rounded-2xl z-10 grid size-9 cursor-pointer place-items-center bg-black/5 text-[#161616]/55 transition hover:bg-black/10 hover:text-[#161616]"
          phx-click="close_user_modal"
          aria-label="Close user details"
        >
          <.icon name="hero-x-mark" class="size-5" />
        </button>
        <p :if={!@selected_user} class="flex min-h-72 items-center justify-center gap-3">
          <span class="loading loading-spinner loading-md text-[#947000]"></span> Loading user
        </p>

        <div :if={@selected_user}>
          <header class="flex items-center gap-4 border-b border-[#ded9ce] px-6 py-6 sm:px-8">
            <div class="grid rounded-2xl size-14 shrink-0 place-items-center bg-[#f4bf25] text-base font-extrabold ">
              {Helpers.user_initials(@selected_user)}
            </div>
            <div class="min-w-0 pr-10">
              <div class="flex flex-wrap items-center gap-2">
                <h2 id="user-modal-title" class="truncate text-xl font-extrabold">
                  {@selected_user.first_name} {@selected_user.last_name}
                </h2>
                <span class="bg-[#e9e3d4] rounded-2xl px-2 py-0.5 text-[0.65rem] font-bold uppercase text-[#68531a]">
                  {@selected_user.role}
                </span>
              </div>
              <p class="mt-1 truncate text-sm text-[#161616]/50">{@selected_user.email}</p>
            </div>
          </header>

          <div class="grid grid-cols-4 border-b border-[#ded9ce] bg-white px-4 sm:px-8">
            <.button
              id="account-info-tab"
              class={[
                "h-12 border-b-2 px-2 text-xs font-bold transition sm:text-sm",
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
                "h-12 border-b-2 px-2 text-xs font-bold transition sm:text-sm",
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
                "h-12 border-b-2 px-2 text-xs font-bold transition sm:text-sm",
                if(@modal_operation == "account_update",
                  do: "border-[#b28708] text-[#735700]",
                  else: "border-transparent text-[#161616]/45 hover:text-[#161616]"
                )
              ]}
              phx-click="update_modal_operation"
              phx-value-operation="account_update"
            >
              Access
            </.button>
            <.button
              id="account-delete-tab"
              class={[
                "h-12 border-b-2 px-2 text-xs font-bold transition sm:text-sm",
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
          </div>

          <div :if={@modal_operation == "account_info"} class="p-6 sm:p-8">
            <dl class="grid gap-x-8 gap-y-5 sm:grid-cols-2">
              <.user_detail label="First name" value={@selected_user.first_name} />
              <.user_detail label="Last name" value={@selected_user.last_name} />
              <.user_detail label="Email" value={@selected_user.email} />
              <.user_detail label="Phone number" value={@selected_user.msisdn} />
              <.user_detail label="Role" value={String.capitalize(to_string(@selected_user.role))} />
              <.user_detail
                label="Access level"
                value={if(@selected_user.is_superuser, do: "Superuser", else: "Standard")}
              />
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
                      <th>Matured At</th>
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
                      <td class="text-xs text-[#161616]/65">{bet.selection}</td>
                      <td class="whitespace-nowrap text-xs text-[#161616]/65">
                        KES {bet.stake_amount}
                      </td>
                      <td class="whitespace-nowrap text-xs text-[#161616]/65">
                        {bet.odds_at_placement}
                      </td>
                      <td class="whitespace-nowrap text-xs text-[#161616]/65">
                        KES {bet.potential_payout}
                      </td>
                      <td class="whitespace-nowrap text-xs text-[#161616]/65">{bet.status}</td>
                      <td class="whitespace-nowrap text-xs text-[#161616]/50">
                        {Helpers.format_date(bet.inserted_at)}
                      </td>
                      <td class="whitespace-nowrap text-xs text-[#161616]/50">
                        <span :if={bet.status == :pending}>
                          -
                        </span>
                        <span :if={bet.status != :pending}>
                          {Helpers.format_date(bet.updated_at)}
                        </span>
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

          <div :if={@modal_operation == "account_update"} class="p-6 sm:p-8">
            <div class="mb-6">
              <h3 class="font-bold">Account access</h3>
              <p class="mt-1 text-sm text-[#161616]/50">
                Control this user's role and elevated permissions.
              </p>
            </div>
            <.form
              :if={@form}
              for={@form}
              id="update_account_form"
              phx-change="validate_user_access"
              phx-submit="save_user_access"
              class="space-y-6"
            >
              <div class="grid gap-6 sm:grid-cols-2">
                <fieldset
                  id="user-role-group"
                  class="fieldset mb-2 w-full"
                  aria-labelledby="user-role-label"
                  disabled={can_elevate_user(@current_scope, @selected_user)}
                >
                  <span id="user-role-label" class="label mb-1">Select Role</span>
                  <div class="grid grid-cols-2 gap-1 rounded-2xl border border-[#d7d2c7] bg-white p-1 transition focus-within:border-[#b28708] focus-within:ring-2 focus-within:ring-[#f4bf25]/20">
                    <label
                      for="user-role-admin"
                      class="flex min-h-10 cursor-pointer items-center justify-center gap-2 rounded-xl px-4 text-sm font-semibold text-[#161616]/60 transition hover:bg-[#f6f4ee] has-[:checked]:bg-[#161616] has-[:checked]:text-white"
                    >
                      <input
                        id="user-role-admin"
                        type="radio"
                        name={@form[:role].name}
                        value="admin"
                        checked={to_string(@form[:role].value) == "admin"}
                        class="radio radio-xs border-current text-[#f4bf25] checked:border-[#f4bf25] checked:bg-[#f4bf25]"
                      /> Admin
                    </label>

                    <label
                      for="user-role-user"
                      class="flex min-h-10 cursor-pointer items-center justify-center gap-2 rounded-xl px-4 text-sm font-semibold text-[#161616]/60 transition hover:bg-[#f6f4ee] has-[:checked]:bg-[#161616] has-[:checked]:text-white"
                    >
                      <input
                        id="user-role-user"
                        type="radio"
                        name={@form[:role].name}
                        value="user"
                        checked={to_string(@form[:role].value) == "user"}
                        class="radio radio-xs border-current text-[#f4bf25] checked:border-[#f4bf25] checked:bg-[#f4bf25]"
                      /> User
                    </label>
                  </div>
                </fieldset>

                <fieldset
                  id="user-superuser-group"
                  class="fieldset mb-2 w-full"
                  aria-labelledby="user-superuser-label"
                  disabled={can_elevate_user(@current_scope, @selected_user)}
                >
                  <span id="user-superuser-label" class="label mb-1">Is Super User</span>
                  <div class="grid grid-cols-2 gap-1 rounded-2xl border border-[#d7d2c7] bg-white p-1 transition focus-within:border-[#b28708] focus-within:ring-2 focus-within:ring-[#f4bf25]/20">
                    <label
                      for="user-superuser-true"
                      class="flex min-h-10 cursor-pointer items-center justify-center gap-2 rounded-xl px-4 text-sm font-semibold text-[#161616]/60 transition hover:bg-[#f6f4ee] has-[:checked]:bg-[#161616] has-[:checked]:text-white"
                    >
                      <input
                        id="user-superuser-true"
                        type="radio"
                        name={@form[:is_superuser].name}
                        value="true"
                        checked={to_string(@form[:is_superuser].value) == "true"}
                        class="radio radio-xs border-current text-[#f4bf25] checked:border-[#f4bf25] checked:bg-[#f4bf25]"
                      /> True
                    </label>

                    <label
                      for="user-superuser-false"
                      class="flex min-h-10 cursor-pointer items-center justify-center gap-2 rounded-xl px-4 text-sm font-semibold text-[#161616]/60 transition hover:bg-[#f6f4ee] has-[:checked]:bg-[#161616] has-[:checked]:text-white"
                    >
                      <input
                        id="user-superuser-false"
                        type="radio"
                        name={@form[:is_superuser].name}
                        value="false"
                        checked={to_string(@form[:is_superuser].value) == "false"}
                        class="radio radio-xs border-current text-[#f4bf25] checked:border-[#f4bf25] checked:bg-[#f4bf25]"
                      /> False
                    </label>
                  </div>
                  <.error :for={{msg, _opts} <- @form[:is_superuser].errors}>{msg}</.error>
                </fieldset>
              </div>

              <div class="flex justify-end border-t border-[#ded9ce] pt-5">
                <.button
                  disabled={can_elevate_user(@current_scope, @selected_user)}
                  phx-disable-with="Saving access ..."
                  class="group rounded-2xl flex h-11 items-center justify-center gap-2 bg-[#161616] px-6 text-sm font-bold text-white transition hover:bg-[#735700] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#b28708]"
                >
                  Save access
                  <.icon
                    name="hero-arrow-right-mini"
                    class="size-4 transition-transform group-hover:translate-x-1"
                  />
                </.button>
              </div>
            </.form>
          </div>

          <div :if={@modal_operation == "account_delete"} class="p-6 sm:p-8">
            <div class="border-l-4 border-red-500 bg-red-50 p-5">
              <div class="flex gap-3">
                <.icon name="hero-exclamation-triangle" class="mt-0.5 size-5 shrink-0 text-red-600" />
                <div>
                  <h3 class="font-bold text-red-950">Delete this user?</h3>
                  <p class="mt-1 text-sm leading-6 text-red-900/65">
                    This permanently removes the account and all associated user data.
                  </p>
                </div>
              </div>
            </div>
            <div class="flex justify-end border-t border-[#ded9ce] pt-5">
              <.button
                phx-disable-with="Deleting account..."
                class="mt-5 rounded-2xl flex h-11 items-center justify-center gap-2 bg-red-600 px-6 text-sm font-bold text-white transition hover:bg-red-700 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600"
                disabled={if(@current_scope.user.id == @selected_user.id, do: true, else: false)}
                phx-click="delete_user"
              >
                <.icon name="hero-trash" class="size-4" /> Delete user
              </.button>
            </div>
          </div>
        </div>
      </div>
      <button class="modal-backdrop" phx-click="close_user_modal" aria-label="Close user details">
        close
      </button>
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

  defp can_elevate_user(current_scope, selected_user) do
    if current_scope.user.id == selected_user.id or current_scope.user.is_superuser == false do
      true
    else
      false
    end
  end
end
