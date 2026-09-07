defmodule BetPeakWeb.AdminLive.Users do
  use BetPeakWeb, :live_view

  alias BetPeak.Accounts
  alias BetPeakWeb.Helpers

  @impl true
  def mount(_params, _session, socket) do
    users = Accounts.get_all_users()

    {:ok,
     socket
     |> assign(users: users)
     |> assign(selected_user: nil)
     |> assign(show_user_modal: false)
     |> assign(modal_operation: "account_update")
     |> assign(form: nil)}
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
    {:noreply, assign(socket, :show_user_modal, false)}
  end

  @impl true
  def handle_event("update_modal_operation", %{"operation" => operation}, socket) do
    {:noreply, assign(socket, :modal_operation, operation)}
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
         |> assign(users: Accounts.get_all_users())
         |> assign(selected_user: user)
         |> assign_form(Accounts.change_user_access(user))
         |> put_flash(:info, "User access updated successfully.")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset, as: :user))
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

          <div class="grid grid-cols-3 border-b border-[#ded9ce] bg-white px-4 sm:px-8">
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
                <.radio_group
                  field={@form[:role]}
                  label="Select role"
                  disabled={can_elevate_user(@current_scope, @selected_user)}
                  options={[
                    {"Admin", "admin"},
                    {"User", "user"}
                  ]}
                />

                <.radio_group
                  field={@form[:is_superuser]}
                  label="Is super user"
                  disabled={can_elevate_user(@current_scope, @selected_user)}
                  options={[
                    {"True", true},
                    {"False", false}
                  ]}
                />
              </div>

              <div class="flex justify-end border-t border-[#ded9ce] pt-5">
                <.button
                  phx-disable-with="Saving access ..."
                  class="group rounded-2xl flex h-11 items-center justify-center gap-2 bg-[#161616] px-6 text-sm font-bold text-white transition hover:bg-[#735700] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#b28708]"
                  disabled={can_elevate_user(@current_scope, @selected_user)}
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
