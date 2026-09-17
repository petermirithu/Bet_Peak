defmodule BetPeakWeb.AdminLive.AccessControlRolesEdit do
  use BetPeakWeb, :live_component

  defp tab_active(role_inherits_permission_tab, tab) do
    if role_inherits_permission_tab == tab do
      "text-[#b28708]"
    else
      ""
    end
  end

  defp role_permissions(%{role_permissions: permissions}) when is_list(permissions),
    do: permissions

  defp role_permissions(_role), do: []

  defp role_inherits(%{parent_inheritances: parent_inheritances}) do
    [] ++ parent_inheritances
  end

  def format_permissions(permissions) when is_list(permissions) do
    permissions
    |> Enum.sort_by(fn permission ->
      {String.downcase(permission.resource.name), String.downcase(permission.action)}
    end)
    |> Enum.map(fn permission ->
      {"#{permission.resource.name} · #{permission.action}", permission.id}
    end)
  end

  def format_permissions(_permissions), do: []

  defp format_roles(roles) when is_list(roles) do
    roles
    |> Enum.sort_by(fn role -> String.downcase(role.name) end)
    |> Enum.map(fn role -> {role.name, role.id} end)
  end

  defp format_roles(_roles), do: []

  def render(assigns) do
    ~H"""
    <div class={["max-h-[calc(90vh-8rem)] overflow-y-auto p-6 sm:p-8"]}>
      <div class={["mb-7"]}>
        <p class={["text-sm leading-6 text-[#161616]/55"]}>
          <%= case @modal_operation do %>
            <% "add" -> %>
              Create a role that can be assigned to application users.
            <% "permission" -> %>
              Select an application permission to attach to this role.
            <% "role_inheritance" -> %>
              Select a parent role to inherit from.
            <% "edit" -> %>
              Update the role and manage its assigned permissions.
          <% end %>
        </p>
      </div>

      <.form
        :if={@form}
        for={@form}
        id="role-form"
        phx-change={
          case @modal_operation do
            "permission" -> "validate_role_permission_form"
            "role_inheritance" -> "validate_role_inheritance_form"
            _ -> "validate_role_form"
          end
        }
        phx-submit={
          case @modal_operation do
            "add" -> "save_role"
            "edit" -> "update_role"
            "permission" -> "save_role_permission"
            "role_inheritance" -> "save_role_inheritance"
          end
        }
        class={["space-y-7"]}
      >
        <div :if={@modal_operation != "permission"} class={["space-y-7"]}>
          <div :if={@modal_operation == "add"} class={["space-y-7"]}>
            <.input
              field={@form[:name]}
              type="text"
              label="Role name"
              autocomplete="off"
              placeholder="e.g. Administrator or Customer Care"
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

            <div class={[
              "flex gap-3 rounded-2xl border border-[#ead890]",
              "bg-[#fff9df] p-4 text-sm text-[#6e5708]"
            ]}>
              <.icon
                name="hero-information-circle"
                class={["mt-0.5 size-5 shrink-0"]}
              />
              <p class={["leading-6"]}>
                Save the role first. Permissions can then be attached from the edit screen.
              </p>
            </div>
          </div>

          <div
            :if={@modal_operation == "edit"}
            id="role-editor-tabs"
          >
            <div class={["grid grid-cols-3 gap-2"]}>
              <div
                phx-click="update_role_permission_tab"
                phx-value-option="role"
                class={[
                  "flex cursor-pointer items-center justify-center gap-2 rounded-xl",
                  "border border-[#ded9ce] bg-white px-3 py-3 text-sm font-bold",
                  "text-[#161616]/50 shadow-sm transition duration-200",
                  "hover:-translate-y-0.5 hover:border-[#b28708] hover:text-[#161616]",
                  tab_active(@role_inherits_permission_tab, "role")
                ]}
              >
                <.icon name="hero-pencil-square" class={["size-4"]} /> Role details
              </div>

              <div
                phx-click="update_role_permission_tab"
                phx-value-option="inherits"
                class={[
                  "flex cursor-pointer items-center justify-center gap-2 rounded-xl",
                  "border border-[#ded9ce] bg-white px-3 py-3 text-sm font-bold",
                  "text-[#161616]/50 shadow-sm transition duration-200",
                  "hover:-translate-y-0.5 hover:border-[#b28708] hover:text-[#161616]",
                  tab_active(@role_inherits_permission_tab, "inherits")
                ]}
              >
                <.icon name="hero-clipboard-document-list" class={["size-4"]} /> Inherits
                <span class={[
                  "inline-flex min-w-6 items-center justify-center rounded-full",
                  "bg-[#f4bf25]/25 px-1.5 py-0.5 text-[11px] font-extrabold",
                  "text-[#735700]"
                ]}>
                  {length(role_inherits(@selected_record))}
                </span>
              </div>

              <div
                phx-click="update_role_permission_tab"
                phx-value-option="permissions"
                class={[
                  "flex cursor-pointer items-center justify-center gap-2 rounded-xl",
                  "border border-[#ded9ce] bg-white px-3 py-3 text-sm font-bold",
                  "text-[#161616]/50 shadow-sm transition duration-200",
                  "hover:-translate-y-0.5 hover:border-[#b28708] hover:text-[#161616]",
                  "peer-focus-visible/permissions:ring-2",
                  "peer-focus-visible/permissions:ring-[#f4bf25]/50",
                  tab_active(@role_inherits_permission_tab, "permissions")
                ]}
              >
                <.icon name="hero-key" class={["size-4"]} /> Permissions
                <span class={[
                  "inline-flex min-w-6 items-center justify-center rounded-full",
                  "bg-[#f4bf25]/25 px-1.5 py-0.5 text-[11px] font-extrabold",
                  "text-[#735700]"
                ]}>
                  {@selected_record.effective_permission_count}
                </span>
              </div>
            </div>

            <section
              :if={@role_inherits_permission_tab == "role"}
              class={[
                "col-span-2 mt-3 rounded-2xl border border-[#ded9ce]",
                "bg-white p-5 shadow-sm sm:p-6"
              ]}
            >
              <div class={["mb-5 flex items-start gap-3"]}>
                <span class={[
                  "grid size-10 shrink-0 place-items-center rounded-xl",
                  "bg-[#161616] text-white"
                ]}>
                  <.icon name="hero-shield-check" class={["size-5"]} />
                </span>

                <div>
                  <h3 class={["font-extrabold text-[#161616]"]}>Role information</h3>
                  <p class={["mt-1 text-sm leading-5 text-[#161616]/50"]}>
                    Update the name used to identify this role.
                  </p>
                </div>
              </div>

              <.input
                field={@form[:name]}
                type="text"
                label="Role name"
                autocomplete="off"
                placeholder="e.g. Administrator or Customer Care"
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
            </section>

            <section
              :if={@role_inherits_permission_tab == "inherits"}
              class={[
                "col-span-2 mt-3 overflow-hidden rounded-2xl",
                "border border-[#ded9ce] bg-white shadow-sm"
              ]}
            >
              <header class={[
                "flex flex-col gap-4 border-b border-[#ebe6dc] bg-[#fcfaf5] p-5",
                "sm:flex-row sm:items-center sm:justify-between"
              ]}>
                <div>
                  <div class={["flex items-center gap-2"]}>
                    <span class={[
                      "grid size-8 place-items-center rounded-lg",
                      "bg-[#fff1b8] text-[#806000]"
                    ]}>
                      <.icon name="hero-clipboard-document-list" class={["size-4"]} />
                    </span>

                    <h3 class={["font-extrabold text-[#161616]"]}>
                      Inherited roles
                    </h3>
                  </div>

                  <p class={["mt-2 text-sm text-[#161616]/50"]}>
                    Manage the roles a role can inherit.
                  </p>
                </div>

                <.button
                  id="attach_role_inheritance"
                  type="button"
                  phx-click="attach_role_inheritance"
                  class={[
                    "group inline-flex h-10 shrink-0 items-center justify-center gap-2",
                    "rounded-xl bg-[#f4bf25] px-4 text-sm font-bold text-[#161616]",
                    "shadow-sm transition duration-200 hover:-translate-y-0.5",
                    "hover:bg-[#ffd34f] hover:shadow-md focus-visible:outline-none",
                    "focus-visible:ring-2 focus-visible:ring-[#f4bf25]/50"
                  ]}
                >
                  <.icon
                    name="hero-plus"
                    class={["size-4 transition-transform group-hover:rotate-90"]}
                  /> Attach inheritance
                </.button>
              </header>

              <div id="assigned-role-inheritance" class={["p-4 sm:p-5"]}>
                <div
                  :if={role_inherits(@selected_record) == []}
                  id="role-inheritances-empty"
                  class={[
                    "flex flex-col items-center rounded-2xl border border-dashed",
                    "border-[#d7d2c7] bg-[#faf8f2] px-5 py-9 text-center"
                  ]}
                >
                  <span class={[
                    "mb-3 grid size-11 place-items-center rounded-full",
                    "bg-white text-[#161616]/30 shadow-sm"
                  ]}>
                    <.icon name="hero-lock-open" class={["size-5"]} />
                  </span>

                  <p class={["text-sm font-bold text-[#161616]"]}>
                    No role inherited
                  </p>
                  <p class={["mt-1 max-w-xs text-xs leading-5 text-[#161616]/45"]}>
                    Attach an inheritance to extent role permissions.
                  </p>
                </div>

                <div
                  :if={role_inherits(@selected_record) != []}
                  id="role-inherits-chips"
                  class={["flex flex-wrap gap-2.5"]}
                >
                  <div
                    :for={role_inheritance <- role_inherits(@selected_record)}
                    id={"role_inheritance-#{role_inheritance.id}"}
                    class={[
                      "group inline-flex min-h-10 max-w-full items-center gap-2 rounded-full",
                      "border border-[#dfd8c8] bg-[#fffdf7] py-1.5 pl-2 pr-1.5",
                      "shadow-sm transition duration-200 hover:-translate-y-0.5",
                      "hover:border-[#d1ad34] hover:bg-[#fff8dc] hover:shadow-md"
                    ]}
                  >
                    <span class={[
                      "grid size-7 shrink-0 place-items-center rounded-full",
                      "bg-[#161616] text-white shadow-sm"
                    ]}>
                      <.icon name="hero-clipboard-document-list" class={["size-3.5"]} />
                    </span>

                    <span class={["flex min-w-0 items-center gap-1.5 text-sm"]}>
                      <span class={[
                        "max-w-36 truncate font-bold text-[#161616]",
                        "sm:max-w-48"
                      ]}>
                        {role_inheritance.parent_role.name}
                      </span>
                    </span>

                    <.button
                      id={"remove-role-inheritance-#{role_inheritance.id}"}
                      type="button"
                      phx-click="delete_role_inheritance"
                      phx-value-role_inheritance_id={role_inheritance.id}
                      title="Remove inheritance"
                      class={[
                        "grid size-7 shrink-0 place-items-center rounded-full",
                        "text-[#161616]/35 transition duration-200",
                        "hover:bg-red-100 hover:text-red-600",
                        "focus-visible:outline-none focus-visible:ring-2",
                        "focus-visible:ring-red-500/30"
                      ]}
                    >
                      <.icon name="hero-x-mark" class={["size-3.5"]} />
                    </.button>
                  </div>
                </div>

                <p
                  :if={role_inherits(@selected_record) != []}
                  class={["mt-4 flex items-center gap-1.5 text-xs text-[#161616]/40"]}
                >
                  <.icon name="hero-information-circle" class={["size-4"]} />
                  Select the close icon on a role to remove it from being inherited.
                </p>
              </div>
            </section>

            <section
              :if={@role_inherits_permission_tab == "permissions"}
              class={[
                "col-span-2 mt-3 overflow-hidden rounded-2xl",
                "border border-[#ded9ce] bg-white shadow-sm"
              ]}
            >
              <header class={[
                "flex flex-col gap-4 border-b border-[#ebe6dc] bg-[#fcfaf5] p-5",
                "sm:flex-row sm:items-center sm:justify-between"
              ]}>
                <div>
                  <div class={["flex items-center gap-2"]}>
                    <span class={[
                      "grid size-8 place-items-center rounded-lg",
                      "bg-[#fff1b8] text-[#806000]"
                    ]}>
                      <.icon name="hero-key" class={["size-4"]} />
                    </span>

                    <h3 class={["font-extrabold text-[#161616]"]}>
                      Assigned permissions
                    </h3>
                  </div>

                  <p class={["mt-2 text-sm text-[#161616]/50"]}>
                    Manage the actions users receive through this role.
                  </p>
                </div>

                <.button
                  id="attach-role-permission"
                  type="button"
                  phx-click="attach_permission"
                  class={[
                    "group inline-flex h-10 shrink-0 items-center justify-center gap-2",
                    "rounded-xl bg-[#f4bf25] px-4 text-sm font-bold text-[#161616]",
                    "shadow-sm transition duration-200 hover:-translate-y-0.5",
                    "hover:bg-[#ffd34f] hover:shadow-md focus-visible:outline-none",
                    "focus-visible:ring-2 focus-visible:ring-[#f4bf25]/50"
                  ]}
                >
                  <.icon
                    name="hero-plus"
                    class={["size-4 transition-transform group-hover:rotate-90"]}
                  /> Attach permission
                </.button>
              </header>

              <div id="assigned-role-permissions" class={["p-4 sm:p-5"]}>
                <div
                  :if={role_permissions(@selected_record) == []}
                  id="role-permissions-empty"
                  class={[
                    "flex flex-col items-center rounded-2xl border border-dashed",
                    "border-[#d7d2c7] bg-[#faf8f2] px-5 py-9 text-center"
                  ]}
                >
                  <span class={[
                    "mb-3 grid size-11 place-items-center rounded-full",
                    "bg-white text-[#161616]/30 shadow-sm"
                  ]}>
                    <.icon name="hero-lock-open" class={["size-5"]} />
                  </span>

                  <p class={["text-sm font-bold text-[#161616]"]}>
                    No permissions assigned
                  </p>
                  <p class={["mt-1 max-w-xs text-xs leading-5 text-[#161616]/45"]}>
                    Attach a permission to grant access to an application resource.
                  </p>
                </div>

                <div
                  :if={role_permissions(@selected_record) != []}
                  id="role-permission-chips"
                  class={["flex flex-wrap gap-2.5"]}
                >
                  <div
                    :for={role_permission <- role_permissions(@selected_record)}
                    id={"role-permission-#{role_permission.role_id}-#{role_permission.permission_id}"}
                    class={[
                      "group inline-flex min-h-10 max-w-full items-center gap-2 rounded-full",
                      "border border-[#dfd8c8] bg-[#fffdf7] py-1.5 pl-2 pr-1.5",
                      "shadow-sm transition duration-200 hover:-translate-y-0.5",
                      "hover:border-[#d1ad34] hover:bg-[#fff8dc] hover:shadow-md"
                    ]}
                  >
                    <span class={[
                      "grid size-7 shrink-0 place-items-center rounded-full",
                      "bg-[#161616] text-white shadow-sm"
                    ]}>
                      <.icon name="hero-key" class={["size-3.5"]} />
                    </span>

                    <span class={["flex min-w-0 items-center gap-1.5 text-sm"]}>
                      <span class={[
                        "max-w-36 truncate font-bold text-[#161616]",
                        "sm:max-w-48"
                      ]}>
                        {role_permission.permission.resource.name}
                      </span>
                      <span aria-hidden="true" class={["text-[#947000]/60"]}>·</span>
                      <span class={[
                        "max-w-28 truncate rounded-full bg-[#f4bf25]/20",
                        "px-2 py-0.5 text-xs font-extrabold capitalize text-[#735700]"
                      ]}>
                        {role_permission.permission.action}
                      </span>
                    </span>

                    <.button
                      id={"remove-role-permission-#{role_permission.role_id}-#{role_permission.permission_id}"}
                      type="button"
                      phx-click="delete_role_permission"
                      phx-value-permission_id={role_permission.permission_id}
                      aria-label={
                              "Remove #{role_permission.permission.action} permission for #{role_permission.permission.resource.name}"
                            }
                      title="Remove permission"
                      class={[
                        "grid size-7 shrink-0 place-items-center rounded-full",
                        "text-[#161616]/35 transition duration-200",
                        "hover:bg-red-100 hover:text-red-600",
                        "focus-visible:outline-none focus-visible:ring-2",
                        "focus-visible:ring-red-500/30"
                      ]}
                    >
                      <.icon name="hero-x-mark" class={["size-3.5"]} />
                    </.button>
                  </div>
                </div>

                <p
                  :if={role_permissions(@selected_record) != []}
                  class={["mt-4 flex items-center gap-1.5 text-xs text-[#161616]/40"]}
                >
                  <.icon name="hero-information-circle" class={["size-4"]} />
                  Select the close icon on a permission to remove it.
                </p>
              </div>
            </section>
          </div>
        </div>

        <div
          :if={@modal_operation == "role_inheritance"}
          class={["space-y-5"]}
        >
          <div class={[
            "rounded-2xl border border-[#ded9ce] bg-white p-5",
            "shadow-sm"
          ]}>
            <div class={["mb-5 flex items-start gap-3"]}>
              <span class={[
                "grid size-10 shrink-0 place-items-center rounded-xl",
                "bg-[#fff1b8] text-[#806000]"
              ]}>
                <.icon name="hero-key" class={["size-5"]} />
              </span>

              <div>
                <h3 class={["font-extrabold"]}>Choose a role to inherit</h3>
                <p class={["mt-1 text-sm leading-5 text-[#161616]/50"]}>
                  Below roles you can inherit from.
                </p>
              </div>
            </div>

            <.input
              field={@form[:parent_role_id]}
              type="select"
              label="Parent Role"
              prompt="Select a Parent Role to inherit"
              options={format_roles(@roles)}
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
          </div>
        </div>

        <div
          :if={@modal_operation == "permission"}
          class={["space-y-5"]}
        >
          <div class={[
            "rounded-2xl border border-[#ded9ce] bg-white p-5",
            "shadow-sm"
          ]}>
            <div class={["mb-5 flex items-start gap-3"]}>
              <span class={[
                "grid size-10 shrink-0 place-items-center rounded-xl",
                "bg-[#fff1b8] text-[#806000]"
              ]}>
                <.icon name="hero-key" class={["size-5"]} />
              </span>

              <div>
                <h3 class={["font-extrabold"]}>Choose a permission</h3>
                <p class={["mt-1 text-sm leading-5 text-[#161616]/50"]}>
                  Permissions are displayed as resource followed by action.
                </p>
              </div>
            </div>

            <.input
              field={@form[:permission_id]}
              type="select"
              label="Permission"
              prompt="Select a permission"
              options={format_permissions(@permissions)}
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
          </div>
        </div>

        <footer class={[
          "flex flex-col-reverse gap-3 border-t border-[#ded9ce] pt-6",
          "sm:flex-row sm:justify-end"
        ]}>
          <.button
            :if={@modal_operation == "permission" or @modal_operation == "role_inheritance"}
            id="back-to-role-editing"
            type="button"
            phx-click="back_to_editing_role"
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
            :if={
              @role_inherits_permission_tab == "role" or @modal_operation == "permission" or
                @modal_operation == "role_inheritance"
            }
            type="submit"
            phx-disable-with={
              case @modal_operation do
                "permission" -> "Attaching permission..."
                "role_inheritance" -> "Attaching inheritance..."
                _ -> "Saving role..."
              end
            }
            class={[
              "group inline-flex h-11 items-center justify-center gap-2",
              "rounded-xl bg-[#161616] px-6 text-sm font-bold text-white",
              "shadow-sm transition duration-200 hover:-translate-y-0.5",
              "hover:bg-[#735700] hover:shadow-md focus-visible:outline-none",
              "focus-visible:ring-2 focus-visible:ring-[#b28708]/40",
              "disabled:cursor-wait disabled:opacity-60"
            ]}
          >
            {case @modal_operation do
              "permission" -> "Attach permission"
              "role_inheritance" -> "Attach inheritance"
              _ -> "Save role"
            end}
            <.icon
              name="hero-arrow-right"
              class={["size-4 transition-transform group-hover:translate-x-1"]}
            />
          </.button>
        </footer>
      </.form>
    </div>
    """
  end
end
