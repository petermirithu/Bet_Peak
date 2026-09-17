defmodule BetPeakWeb.AdminLive.AccessControlPermissions do
  use BetPeakWeb, :live_component

  defp format_resources(resources) when is_list(resources) do
    resources
    |> Enum.sort_by(&String.downcase(&1.name))
    |> Enum.map(&{&1.name, &1.id})
  end

  defp format_resources(_resources), do: []

  defp permission_name(%{action: action}) when is_binary(action), do: action
  defp permission_name(_permission), do: "Permission"

  def render(assigns) do
    ~H"""
    <dialog
      id="permission-modal"
      open={@show_permission_modal}
      aria-labelledby="permission-modal-title"
      phx-window-keydown="close_permission_modal"
      phx-key="escape"
      class={[
        "fixed inset-0 z-50 m-0 hidden h-screen max-h-none w-screen max-w-none",
        "items-center justify-center overflow-y-auto border-0 bg-transparent p-4",
        "open:flex"
      ]}
    >
      <.button
        id="permission-modal-backdrop"
        type="button"
        phx-click="close_permission_modal"
        aria-label="Close permission dialog"
        class={[
          "absolute inset-0 cursor-default bg-[#161616]/60 backdrop-blur-sm",
          "transition-opacity"
        ]}
      >
        <span class={["sr-only"]}>Close</span>
      </.button>

      <div class={[
        "relative z-10 w-full max-w-lg overflow-hidden rounded-3xl",
        "border border-white/40 bg-[#f8f6f0] text-[#161616]",
        "shadow-[0_30px_90px_rgba(0,0,0,0.35)]"
      ]}>
        <.button
          id="close-permission-modal"
          type="button"
          phx-click="close_permission_modal"
          aria-label="Close permission dialog"
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

        <div :if={@show_permission_modal}>
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
                <.icon name="hero-key" class={["size-6"]} />
              </span>

              <div class={["min-w-0"]}>
                <p class={["mb-1 text-xs font-bold text-[#947000]"]}>
                  Access control
                </p>

                <h2
                  id="permission-modal-title"
                  class={["truncate text-xl font-extrabold sm:text-2xl"]}
                >
                  <%= case @modal_operation do %>
                    <% "add" -> %>
                      Add new permission
                    <% "edit" -> %>
                      Edit {permission_name(@selected_record)}
                    <% "delete" -> %>
                      Delete {permission_name(@selected_record)}
                  <% end %>
                </h2>
              </div>
            </div>
          </header>

          <div
            :if={@modal_operation in ["add", "edit"]}
            class={["max-h-[calc(90vh-8rem)] overflow-y-auto p-6 sm:p-8"]}
          >
            <div class={["mb-7"]}>
              <p class={["text-sm leading-6 text-[#161616]/55"]}>
                {if(@modal_operation == "add",
                  do: "Define an action that can be granted for a protected resource.",
                  else: "Update the protected resource or action for this permission."
                )}
              </p>
            </div>

            <.form
              :if={@form}
              for={@form}
              id="permission-form"
              phx-change="validate_permission_form"
              phx-submit={
                if(@modal_operation == "add", do: "save_permission", else: "update_permission")
              }
              class={["space-y-7"]}
            >
              <div class={[
                "space-y-5 rounded-2xl border border-[#ded9ce] bg-white p-5",
                "shadow-sm sm:p-6"
              ]}>
                <div class={["flex items-start gap-3"]}>
                  <span class={[
                    "grid size-10 shrink-0 place-items-center rounded-xl",
                    "bg-[#fff1b8] text-[#806000]"
                  ]}>
                    <.icon name="hero-key" class={["size-5"]} />
                  </span>

                  <div>
                    <h3 class={["font-extrabold text-[#161616]"]}>Permission information</h3>
                    <p class={["mt-1 text-sm leading-5 text-[#161616]/50"]}>
                      Pair a protected resource with the action users may perform.
                    </p>
                  </div>
                </div>

                <.input
                  field={@form[:resource_id]}
                  type="select"
                  label="Resource"
                  prompt="Select a resource"
                  options={format_resources(@resources)}
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

                <.input
                  field={@form[:action]}
                  type="text"
                  label="Action"
                  autocomplete="permission-action"
                  placeholder="e.g. Read, Write, Validate, Update, Delete"
                  spellcheck="true"
                  required
                  class={[
                    "h-12 w-full rounded-2xl border border-[#d7d2c7] bg-white px-4",
                    "text-[#161616] shadow-sm outline-none transition duration-200",
                    "placeholder:text-[#161616]/30 hover:border-[#b8ae9c]",
                    "focus:border-[#b28708] focus:ring-2 focus:ring-[#f4bf25]/20"
                  ]}
                  error_class={[
                    "border-[#b42318] focus:border-[#b42318]",
                    "focus:ring-[#b42318]/15"
                  ]}
                />
              </div>

              <footer class={[
                "flex flex-col-reverse gap-3 border-t border-[#ded9ce] pt-6",
                "sm:flex-row sm:justify-end"
              ]}>
                <.button
                  id="cancel-permission-form"
                  type="button"
                  phx-click="close_permission_modal"
                  class={[
                    "inline-flex h-11 items-center justify-center rounded-xl",
                    "border border-[#d7d2c7] bg-white px-5 text-sm font-bold",
                    "text-[#161616] transition hover:bg-[#f2efe7]",
                    "focus-visible:outline-none focus-visible:ring-2",
                    "focus-visible:ring-[#161616]/15"
                  ]}
                >
                  Cancel
                </.button>

                <.button
                  id="submit-permission-form"
                  type="submit"
                  phx-disable-with="Saving permission..."
                  class={[
                    "group inline-flex h-11 items-center justify-center gap-2",
                    "rounded-xl bg-[#161616] px-6 text-sm font-bold text-white",
                    "shadow-sm transition duration-200 hover:-translate-y-0.5",
                    "hover:bg-[#735700] hover:shadow-md focus-visible:outline-none",
                    "focus-visible:ring-2 focus-visible:ring-[#b28708]/40",
                    "disabled:cursor-wait disabled:opacity-60"
                  ]}
                >
                  {if(@modal_operation == "add", do: "Create permission", else: "Save changes")}
                  <.icon
                    name="hero-arrow-right-mini"
                    class="size-4 transition-transform group-hover:translate-x-1"
                  />
                </.button>
              </footer>
            </.form>
          </div>

          <div :if={@modal_operation == "delete"} class={["p-6 sm:p-8"]}>
            <div class={["rounded-2xl border border-red-200 bg-red-50 p-5"]}>
              <div class={["flex gap-4"]}>
                <span class={[
                  "grid size-10 shrink-0 place-items-center rounded-xl",
                  "bg-red-100 text-red-700"
                ]}>
                  <.icon name="hero-exclamation-triangle" class={["size-5"]} />
                </span>

                <div>
                  <h3 class={["font-extrabold text-red-950"]}>Delete this permission?</h3>
                  <p class={["mt-1 text-sm leading-6 text-red-900/65"]}>
                    Roles using this permission will lose the associated access.
                  </p>
                </div>
              </div>
            </div>

            <div class={[
              "mt-6 flex flex-col-reverse gap-3 border-t border-[#ded9ce]",
              "pt-6 sm:flex-row sm:justify-end"
            ]}>
              <.button
                id="cancel-delete-permission"
                type="button"
                phx-click="close_permission_modal"
                class={[
                  "inline-flex h-11 items-center justify-center rounded-xl",
                  "border border-[#d7d2c7] bg-white px-5 text-sm font-bold",
                  "transition hover:bg-[#f2efe7]"
                ]}
              >
                Cancel
              </.button>

              <.button
                id="confirm-delete-permission"
                phx-disable-with="Deleting permission..."
                phx-click="delete_permission"
                class={[
                  "inline-flex h-11 items-center justify-center gap-2 rounded-xl",
                  "bg-red-600 px-6 text-sm font-bold text-white shadow-sm",
                  "transition hover:bg-red-700 focus-visible:outline-none",
                  "focus-visible:ring-2 focus-visible:ring-red-600/30",
                  "disabled:cursor-wait disabled:opacity-60"
                ]}
              >
                <.icon name="hero-trash" class="size-4" /> Delete permission
              </.button>
            </div>
          </div>
        </div>
      </div>
    </dialog>
    """
  end
end
