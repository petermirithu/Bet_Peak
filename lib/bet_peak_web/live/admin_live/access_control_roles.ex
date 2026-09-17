defmodule BetPeakWeb.AdminLive.AccessControlRoles do
  use BetPeakWeb, :live_component

  defp role_name(%{name: name}) when is_binary(name), do: name
  defp role_name(_role), do: "Role"

  def render(assigns) do
    ~H"""
    <dialog
      id="role-modal"
      open={@show_role_modal}
      aria-labelledby="role-modal-title"
      phx-window-keydown="close_role_modal"
      phx-key="escape"
      class={[
        "fixed inset-0 z-50 m-0 hidden h-screen max-h-none w-screen max-w-none",
        "items-center justify-center overflow-y-auto border-0 bg-transparent p-4",
        "open:flex"
      ]}
    >
      <.button
        id="role-modal-backdrop"
        type="button"
        phx-click="close_role_modal"
        aria-label="Close role dialog"
        class={[
          "absolute inset-0 cursor-default bg-[#161616]/60 backdrop-blur-sm",
          "transition-opacity"
        ]}
      >
        <span class={["sr-only"]}>Close</span>
      </.button>

      <div class={[
        "relative z-10 w-full max-w-xl overflow-hidden rounded-3xl",
        "border border-white/40 bg-[#f8f6f0] text-[#161616]",
        "shadow-[0_30px_90px_rgba(0,0,0,0.35)]"
      ]}>
        <.button
          id="close-role-modal"
          type="button"
          phx-click="close_role_modal"
          aria-label="Close role dialog"
          class={[
            "absolute right-5 top-5 z-20 grid size-10 place-items-center rounded-full cursor-pointer",
            "border border-[#ded9ce] bg-white text-[#161616]/55 shadow-sm",
            "transition duration-200 hover:rotate-90 hover:border-[#b28708]",
            "hover:text-[#161616] focus-visible:outline-none",
            "focus-visible:ring-2 focus-visible:ring-[#f4bf25]/50"
          ]}
        >
          <.icon name="hero-x-mark" class={["size-5"]} />
        </.button>

        <div :if={@show_role_modal}>
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
              <span class={[
                "grid size-12 shrink-0 place-items-center rounded-2xl",
                "bg-[#161616] text-white shadow-lg shadow-black/10"
              ]}>
                <.icon name="hero-shield-check" class={["size-6"]} />
              </span>

              <div class={["min-w-0"]}>
                <p class={[
                  "mb-1 text-xs font-bold",
                  "text-[#947000]"
                ]}>
                  Access control
                </p>

                <h2 id="role-modal-title" class={["truncate text-xl font-extrabold sm:text-2xl"]}>
                  <%= case @modal_operation do %>
                    <% "add" -> %>
                      Add new role
                    <% "edit" -> %>
                      Edit {role_name(@selected_record)}
                    <% "permission" -> %>
                      Attach permission to {role_name(@selected_record)}
                    <% "role_inheritance" -> %>
                      Attach inheritance to {role_name(@selected_record)}
                    <% "delete" -> %>
                      Delete {role_name(@selected_record)}
                  <% end %>
                </h2>
              </div>
            </div>
          </header>

          <div :if={@modal_operation in ["add", "edit", "permission", "role_inheritance"]}>
            <.live_component
              module={BetPeakWeb.AdminLive.AccessControlRolesEdit}
              modal_operation={@modal_operation}
              selected_record={@selected_record}
              form={@form}
              role_inherits_permission_tab={@role_inherits_permission_tab}
              permissions={@permissions}
              roles={@roles}
              id="role_edit_section"
            />
          </div>

          <div
            :if={@modal_operation == "delete"}
            class={["p-6 sm:p-8"]}
          >
            <div class={[
              "rounded-2xl border border-red-200 bg-red-50 p-5"
            ]}>
              <div class={["flex gap-4"]}>
                <span class={[
                  "grid size-10 shrink-0 place-items-center rounded-xl",
                  "bg-red-100 text-red-700"
                ]}>
                  <.icon name="hero-exclamation-triangle" class={["size-5"]} />
                </span>

                <div>
                  <h3 class={["font-extrabold text-red-950"]}>Delete this role?</h3>
                  <p class={["mt-1 text-sm leading-6 text-red-900/65"]}>
                    Users assigned to this role will lose the access granted through it.
                  </p>
                </div>
              </div>
            </div>

            <div class={[
              "mt-6 flex flex-col-reverse gap-3 border-t border-[#ded9ce]",
              "pt-6 sm:flex-row sm:justify-end"
            ]}>
              <.button
                id="cancel-delete-role"
                type="button"
                phx-click="close_role_modal"
                class={[
                  "inline-flex h-11 items-center justify-center rounded-xl",
                  "border border-[#d7d2c7] bg-white px-5 text-sm font-bold",
                  "transition hover:bg-[#f2efe7]"
                ]}
              >
                Cancel
              </.button>

              <.button
                id="confirm-delete-role"
                phx-click="delete_role"
                phx-disable-with="Deleting role..."
                class={[
                  "inline-flex h-11 items-center justify-center gap-2 rounded-xl",
                  "bg-red-600 px-6 text-sm font-bold text-white shadow-sm",
                  "transition hover:bg-red-700 focus-visible:outline-none",
                  "focus-visible:ring-2 focus-visible:ring-red-600/30",
                  "disabled:cursor-wait disabled:opacity-60"
                ]}
              >
                <.icon name="hero-trash" class={["size-4"]} /> Delete role
              </.button>
            </div>
          </div>
        </div>
      </div>
    </dialog>
    """
  end
end
