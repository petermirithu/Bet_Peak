defmodule BetPeakWeb.AdminLive.AccessControlResources do
  use BetPeakWeb, :live_component

  defp resource_name(%{name: name}) when is_binary(name), do: name
  defp resource_name(_resource), do: "Resource"

  def render(assigns) do
    ~H"""
    <dialog
      id="resource-modal"
      open={@show_resource_modal}
      aria-labelledby="resource-modal-title"
      phx-window-keydown="close_resource_modal"
      phx-key="escape"
      class={[
        "fixed inset-0 z-50 m-0 hidden h-screen max-h-none w-screen max-w-none",
        "items-center justify-center overflow-y-auto border-0 bg-transparent p-4",
        "open:flex"
      ]}
    >
      <.button
        id="resource-modal-backdrop"
        type="button"
        phx-click="close_resource_modal"
        aria-label="Close resource dialog"
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
          id="close-resource-modal"
          type="button"
          phx-click="close_resource_modal"
          aria-label="Close resource dialog"
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

        <div :if={@show_resource_modal}>
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
                <.icon name="hero-squares-2x2" class={["size-6"]} />
              </span>

              <div class={["min-w-0"]}>
                <p class={["mb-1 text-xs font-bold text-[#947000]"]}>
                  Access control
                </p>

                <h2 id="resource-modal-title" class={["truncate text-xl font-extrabold sm:text-2xl"]}>
                  <%= case @modal_operation do %>
                    <% "add" -> %>
                      Add new resource
                    <% "edit" -> %>
                      Edit {resource_name(@selected_record)}
                    <% "delete" -> %>
                      Delete {resource_name(@selected_record)}
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
                  do: "Register an application area that can be protected by permissions.",
                  else: "Update the name used to identify this protected application area."
                )}
              </p>
            </div>

            <.form
              :if={@form}
              for={@form}
              id="resource-form"
              phx-change="validate_resource_form"
              phx-submit={if(@modal_operation == "add", do: "save_resource", else: "update_resource")}
              class={["space-y-7"]}
            >
              <div class={[
                "rounded-2xl border border-[#ded9ce] bg-white p-5 shadow-sm",
                "sm:p-6"
              ]}>
                <div class={["mb-5 flex items-start gap-3"]}>
                  <span class={[
                    "grid size-10 shrink-0 place-items-center rounded-xl",
                    "bg-[#fff1b8] text-[#806000]"
                  ]}>
                    <.icon name="hero-squares-2x2" class={["size-5"]} />
                  </span>

                  <div>
                    <h3 class={["font-extrabold text-[#161616]"]}>Resource information</h3>
                    <p class={["mt-1 text-sm leading-5 text-[#161616]/50"]}>
                      Use a clear name that matches the application area being protected.
                    </p>
                  </div>
                </div>

                <.input
                  field={@form[:name]}
                  type="text"
                  label="Resource name"
                  autocomplete="resource-name"
                  placeholder="e.g. Sports, Users, Teams"
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
                  id="cancel-resource-form"
                  type="button"
                  phx-click="close_resource_modal"
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
                  id="submit-resource-form"
                  type="submit"
                  phx-disable-with="Saving resource..."
                  class={[
                    "group inline-flex h-11 items-center justify-center gap-2",
                    "rounded-xl bg-[#161616] px-6 text-sm font-bold text-white",
                    "shadow-sm transition duration-200 hover:-translate-y-0.5",
                    "hover:bg-[#735700] hover:shadow-md focus-visible:outline-none",
                    "focus-visible:ring-2 focus-visible:ring-[#b28708]/40",
                    "disabled:cursor-wait disabled:opacity-60"
                  ]}
                >
                  {if(@modal_operation == "add", do: "Create resource", else: "Save changes")}
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
                  <h3 class={["font-extrabold text-red-950"]}>Delete this resource?</h3>
                  <p class={["mt-1 text-sm leading-6 text-red-900/65"]}>
                    Permissions attached to this resource may also be affected.
                  </p>
                </div>
              </div>
            </div>

            <div class={[
              "mt-6 flex flex-col-reverse gap-3 border-t border-[#ded9ce]",
              "pt-6 sm:flex-row sm:justify-end"
            ]}>
              <.button
                id="cancel-delete-resource"
                type="button"
                phx-click="close_resource_modal"
                class={[
                  "inline-flex h-11 items-center justify-center rounded-xl",
                  "border border-[#d7d2c7] bg-white px-5 text-sm font-bold",
                  "transition hover:bg-[#f2efe7]"
                ]}
              >
                Cancel
              </.button>

              <.button
                id="confirm-delete-resource"
                phx-disable-with="Deleting resource..."
                phx-click="delete_resource"
                class={[
                  "inline-flex h-11 items-center justify-center gap-2 rounded-xl",
                  "bg-red-600 px-6 text-sm font-bold text-white shadow-sm",
                  "transition hover:bg-red-700 focus-visible:outline-none",
                  "focus-visible:ring-2 focus-visible:ring-red-600/30",
                  "disabled:cursor-wait disabled:opacity-60"
                ]}
              >
                <.icon name="hero-trash" class="size-4" /> Delete resource
              </.button>
            </div>
          </div>
        </div>
      </div>
    </dialog>
    """
  end
end
