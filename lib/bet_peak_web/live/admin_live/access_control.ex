defmodule BetPeakWeb.AdminLive.AccessControl do
  use BetPeakWeb, :live_view

  alias BetPeak.Roles
  alias BetPeak.Roles.Role
  alias BetPeak.Permissions
  alias BetPeak.Permissions.Permission
  alias BetPeak.Resources
  alias BetPeak.Resources.Resource
  alias BetPeakWeb.Helpers
  alias BetPeak.RolePermissions
  alias BetPeak.RolePermissions.RolePermission
  alias BetPeak.RoleInherits
  alias BetPeak.RoleInherits.RoleInherit

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(roles: Roles.fetch_all(socket.assigns.current_scope))
     |> assign(permissions: Permissions.fetch_all(socket.assigns.current_scope))
     |> assign(resources: Resources.fetch_all(socket.assigns.current_scope))
     |> assign(selected_access_control: "roles")
     |> reset_states()}
  end

  defp reset_states(socket) do
    socket
    |> assign(show_role_modal: false)
    |> assign(show_permission_modal: false)
    |> assign(show_resource_modal: false)
    |> assign(modal_operation: nil)
    |> assign(selected_record: nil)
    |> assign(role_inherits_permission_tab: "role")
    |> assign(form: nil)
  end

  # ***************************************************************************************
  # ------------------------------------ Roles Section ------------------------------------
  # ***************************************************************************************
  @impl true
  def handle_event("open_role_modal", %{"operation" => operation, "role_id" => role_id}, socket) do
    case operation do
      "add" ->
        changeset =
          Roles.change_creation(%Role{}, %{}, validate_unique: false)

        {
          :noreply,
          socket
          |> assign(selected_access_control: "roles")
          |> assign(show_role_modal: true)
          |> assign(modal_operation: operation)
          |> assign_form(changeset, "role")
        }

      "edit" ->
        role = Enum.find(socket.assigns.roles, &(&1.id == String.to_integer(role_id)))

        changeset =
          Roles.change_creation(role, %{}, validate_unique: false)

        {
          :noreply,
          socket
          |> assign(selected_access_control: "roles")
          |> assign(selected_record: role)
          |> assign(modal_operation: operation)
          |> assign_form(Map.put(changeset, :action, :validate), "role")
          |> assign(show_role_modal: true)
        }

      "delete" ->
        role = Enum.find(socket.assigns.roles, &(&1.id == String.to_integer(role_id)))

        {
          :noreply,
          socket
          |> assign(selected_access_control: "roles")
          |> assign(show_role_modal: true)
          |> assign(selected_record: role)
          |> assign(modal_operation: operation)
        }
    end
  end

  @impl true
  def handle_event("validate_role_form", %{"role" => role_params}, socket) do
    changeset =
      case socket.assigns.modal_operation do
        "edit" ->
          Roles.change_creation(
            socket.assigns.selected_record,
            role_params,
            validate_unique: false
          )

        _ ->
          Roles.change_creation(%Role{}, role_params, validate_unique: false)
      end

    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate), "role")}
  end

  @impl true
  def handle_event("save_role", %{"role" => role_params}, socket) do
    case Roles.save(socket.assigns.current_scope, role_params) do
      {:ok, _role} ->
        {:noreply,
         socket
         |> assign(roles: Roles.fetch_all(socket.assigns.current_scope))
         |> put_flash(:info, "Successfully created the role")
         |> close_modal()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset, "role")}

      {:error, :unauthorized} ->
        {:noreply, socket |> put_flash(:error, "You are not authorized to add a role!")}

      {:error, _} ->
        render_default_form_error(socket, "adding", "role")
    end
  end

  @impl true
  def handle_event("update_role", %{"role" => role_params}, socket) do
    case Roles.update(
           socket.assigns.current_scope,
           socket.assigns.selected_record,
           role_params
         ) do
      {:ok, _role} ->
        {:noreply,
         socket
         |> assign(roles: Roles.fetch_all(socket.assigns.current_scope))
         |> put_flash(:info, "Successfully updated the role")
         |> close_modal()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset, "role")}

      {:error, :unauthorized} ->
        {:noreply, socket |> put_flash(:error, "You are not authorized to update a role!")}

      {:error, _} ->
        render_default_form_error(socket, "updating", "role")
    end
  end

  @impl true
  def handle_event("delete_role", _params, socket) do
    case Roles.delete(socket.assigns.current_scope, socket.assigns.selected_record) do
      {:ok, _role} ->
        {:noreply,
         socket
         |> assign(roles: Roles.fetch_all(socket.assigns.current_scope))
         |> put_flash(:info, "Successfully delete the role")
         |> close_modal()}

      {:error, :unauthorized} ->
        {:noreply, socket |> put_flash(:error, "You are not authorized to delete a role!")}

      {:error, _} ->
        render_default_form_error(socket, "deleting", "role")
    end
  end

  @impl true
  def handle_event("close_role_modal", _params, socket) do
    {
      :noreply,
      socket
      |> close_modal()
    }
  end

  # *********************************************************************************************
  # ------------------------------------ End of Role Section ------------------------------------
  # *********************************************************************************************

  # *********************************************************************************************
  # ------------------------------------ Role Inheritance Section -------------------------------
  # *********************************************************************************************

  @impl true
  def handle_event("attach_role_inheritance", _params, socket) do
    changeset =
      RoleInherits.change_creation(%RoleInherit{}, %{}, validate_unique: false)

    {
      :noreply,
      socket
      |> assign(modal_operation: "role_inheritance")
      |> assign_form(changeset, "role_inheritance")
    }
  end

  @impl true
  def handle_event(
        "validate_role_inheritance_form",
        %{"role_inheritance" => role_inheritance},
        socket
      ) do
    role_inheritance_params =
      Map.put(role_inheritance, "child_role_id", socket.assigns.selected_record.id)

    changeset =
      RoleInherits.change_creation(
        %RoleInherit{},
        role_inheritance_params,
        validate_unique: false
      )

    IO.inspect(changeset)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate), "role_inheritance")}
  end

  @impl true
  def handle_event("save_role_inheritance", %{"role_inheritance" => role_inheritance}, socket) do
    role_inheritance_params =
      Map.put(role_inheritance, "child_role_id", socket.assigns.selected_record.id)

    case RoleInherits.save(socket.assigns.current_scope, role_inheritance_params) do
      {:ok, _role} ->
        roles = Roles.fetch_all(socket.assigns.current_scope)

        {:noreply,
         socket
         |> assign(roles: roles)
         |> assign(
           selected_record: Enum.find(roles, &(&1.id == socket.assigns.selected_record.id))
         )
         |> put_flash(:info, "Successfully inherited the role")
         |> back_to_editing_role()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset, "role_inheritance")}

      {:error, :unauthorized} ->
        {:noreply, socket |> put_flash(:error, "You are not authorized to add role inheritance!")}

      {:error, _} ->
        render_default_form_error(socket, "adding", "role inheritance")
    end
  end

  @impl true
  def handle_event(
        "delete_role_inheritance",
        %{"role_inheritance_id" => role_inheritance_id},
        socket
      ) do
    role_inheritance =
      Enum.find(
        socket.assigns.selected_record.parent_inheritances,
        &(&1.id == String.to_integer(role_inheritance_id))
      )

    case RoleInherits.delete(socket.assigns.current_scope, role_inheritance) do
      {:ok, _role} ->
        roles = Roles.fetch_all(socket.assigns.current_scope)

        {:noreply,
         socket
         |> assign(roles: roles)
         |> assign(
           selected_record: Enum.find(roles, &(&1.id == socket.assigns.selected_record.id))
         )
         |> put_flash(:info, "Successfully delete the role inheritance")}

      {:error, :unauthorized} ->
        {:noreply,
         socket |> put_flash(:error, "You are not authorized to delete a role inheritance!")}

      {:error, _} ->
        render_default_form_error(socket, "deleting", "role inheritance")
    end
  end

  # *********************************************************************************************
  # ------------------------------------ End of Role Inheritance Section ------------------------
  # *********************************************************************************************

  # *********************************************************************************************
  # ------------------------------------ Role Permissions Section -------------------------------
  # *********************************************************************************************

  @impl true
  def handle_event("save_role_permission", %{"role_permission" => role_permission}, socket) do
    role_permission_params =
      Map.put(role_permission, "role_id", socket.assigns.selected_record.id)

    case RolePermissions.save(socket.assigns.current_scope, role_permission_params) do
      {:ok, _role} ->
        roles = Roles.fetch_all(socket.assigns.current_scope)

        {:noreply,
         socket
         |> assign(roles: roles)
         |> assign(
           selected_record: Enum.find(roles, &(&1.id == socket.assigns.selected_record.id))
         )
         |> put_flash(:info, "Successfully attached the permission to the role")
         |> back_to_editing_role()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset, "role_permission")}

      {:error, :unauthorized} ->
        {:noreply,
         socket |> put_flash(:error, "You are not authorized to add a role permission!")}

      {:error, _} ->
        render_default_form_error(socket, "adding", "role_permission")
    end
  end

  @impl true
  def handle_event(
        "delete_role_permission",
        %{"permission_id" => permission_id},
        socket
      ) do
    role_permission =
      Enum.find(
        socket.assigns.selected_record.role_permissions,
        &(&1.permission_id == String.to_integer(permission_id) and
            &1.role_id == socket.assigns.selected_record.id)
      )

    case RolePermissions.delete(socket.assigns.current_scope, role_permission) do
      {:ok, _role} ->
        roles = Roles.fetch_all(socket.assigns.current_scope)

        {:noreply,
         socket
         |> assign(roles: roles)
         |> assign(
           selected_record: Enum.find(roles, &(&1.id == socket.assigns.selected_record.id))
         )
         |> put_flash(:info, "Successfully delete the role permission")}

      {:error, :unauthorized} ->
        {:noreply,
         socket |> put_flash(:error, "You are not authorized to remove a role permission!")}

      {:error, _} ->
        render_default_form_error(socket, "deleting", "role")
    end
  end

  @impl true
  def handle_event(
        "validate_role_permission_form",
        %{"role_permission" => role_permission},
        socket
      ) do
    role_permission_params =
      Map.put(role_permission, "role_id", socket.assigns.selected_record.id)

    changeset =
      RolePermissions.change_creation(
        %RolePermission{},
        role_permission_params,
        validate_unique: false
      )

    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate), "role_permission")}
  end

  @impl true
  def handle_event("attach_permission", _params, socket) do
    changeset =
      RolePermissions.change_creation(%RolePermission{}, %{}, validate_unique: false)

    {
      :noreply,
      socket
      |> assign(modal_operation: "permission")
      |> assign_form(changeset, "role_permission")
    }
  end

  @impl true
  def handle_event("back_to_editing_role", _params, socket) do
    {:noreply,
     socket
     |> back_to_editing_role()}
  end

  @impl true
  def handle_event("update_role_permission_tab", %{"option" => option}, socket) do
    {:noreply,
     socket
     |> assign(role_inherits_permission_tab: option)}
  end

  # *********************************************************************************************
  # ------------------------------------ End of Role Permissions Section ------------------------
  # *********************************************************************************************

  # *********************************************************************************************
  # ------------------------------------ Permissions Section ------------------------------------
  # *********************************************************************************************
  @impl true
  def handle_event(
        "open_permission_modal",
        %{"operation" => operation, "permission_id" => permission_id},
        socket
      ) do
    case operation do
      "add" ->
        changeset =
          Permissions.change_creation(%Permission{}, %{}, validate_unique: false)

        {
          :noreply,
          socket
          |> assign(selected_access_control: "permissions")
          |> assign(show_permission_modal: true)
          |> assign(modal_operation: operation)
          |> assign_form(changeset, "permission")
        }

      "edit" ->
        permission =
          Enum.find(socket.assigns.permissions, &(&1.id == String.to_integer(permission_id)))

        changeset =
          Permissions.change_creation(permission, %{}, validate_unique: false)

        {
          :noreply,
          socket
          |> assign(selected_access_control: "permissions")
          |> assign(selected_record: permission)
          |> assign(modal_operation: operation)
          |> assign_form(Map.put(changeset, :action, :validate), "permission")
          |> assign(show_permission_modal: true)
        }

      "delete" ->
        permission =
          Enum.find(socket.assigns.permissions, &(&1.id == String.to_integer(permission_id)))

        {
          :noreply,
          socket
          |> assign(selected_access_control: "permissions")
          |> assign(show_permission_modal: true)
          |> assign(selected_record: permission)
          |> assign(modal_operation: operation)
        }
    end
  end

  @impl true
  def handle_event("validate_permission_form", %{"permission" => permission_params}, socket) do
    changeset =
      Permissions.change_creation(%Permission{}, permission_params, validate_unique: false)

    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate), "permission")}
  end

  @impl true
  def handle_event("save_permission", %{"permission" => permission_params}, socket) do
    case Permissions.save(socket.assigns.current_scope, permission_params) do
      {:ok, _permission} ->
        {:noreply,
         socket
         |> assign(permissions: Permissions.fetch_all(socket.assigns.current_scope))
         |> put_flash(:info, "Successfully created the permission")
         |> close_modal()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset, "permission")}

      {:error, :unauthorized} ->
        {:noreply, socket |> put_flash(:error, "You are not authorized to add a permission!")}

      {:error, _} ->
        render_default_form_error(socket, "adding", "permission")
    end
  end

  @impl true
  def handle_event("update_permission", %{"permission" => permission_params}, socket) do
    case Permissions.update(
           socket.assigns.current_scope,
           socket.assigns.selected_record,
           permission_params
         ) do
      {:ok, _permission} ->
        {:noreply,
         socket
         |> assign(permissions: Permissions.fetch_all(socket.assigns.current_scope))
         |> put_flash(:info, "Successfully updated the permission")
         |> close_modal()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset, "permission")}

      {:error, :unauthorized} ->
        {:noreply, socket |> put_flash(:error, "You are not authorized to update a permission!")}

      {:error, _} ->
        render_default_form_error(socket, "updating", "permission")
    end
  end

  @impl true
  def handle_event("delete_permission", _params, socket) do
    case Permissions.delete(socket.assigns.current_scope, socket.assigns.selected_record) do
      {:ok, _permission} ->
        {:noreply,
         socket
         |> assign(permissions: Permissions.fetch_all(socket.assigns.current_scope))
         |> put_flash(:info, "Successfully delete the permission")
         |> close_modal()}

      {:error, :unauthorized} ->
        {:noreply, socket |> put_flash(:error, "You are not authorized to delete a permission!")}

      {:error, _} ->
        render_default_form_error(socket, "deleting", "permission")
    end
  end

  @impl true
  def handle_event("close_permission_modal", _params, socket) do
    {
      :noreply,
      socket
      |> close_modal()
    }
  end

  # *********************************************************************************************
  # ------------------------------------ End of Permissions Section ------------------------------------
  # *********************************************************************************************

  # *********************************************************************************************
  # ------------------------------------ Resources Section --------------------------------------
  # *********************************************************************************************
  @impl true
  def handle_event(
        "open_resource_modal",
        %{"operation" => operation, "resource_id" => resource_id},
        socket
      ) do
    case operation do
      "add" ->
        changeset =
          Resources.change_creation(%Resource{}, %{}, validate_unique: false)

        {
          :noreply,
          socket
          |> assign(selected_access_control: "resources")
          |> assign(show_resource_modal: true)
          |> assign(modal_operation: operation)
          |> assign_form(changeset, "resource")
        }

      "edit" ->
        resource =
          Enum.find(socket.assigns.resources, &(&1.id == String.to_integer(resource_id)))

        changeset =
          Resources.change_creation(resource, %{}, validate_unique: false)

        {
          :noreply,
          socket
          |> assign(selected_access_control: "resources")
          |> assign(selected_record: resource)
          |> assign(modal_operation: operation)
          |> assign_form(Map.put(changeset, :action, :validate), "resource")
          |> assign(show_resource_modal: true)
        }

      "delete" ->
        resource =
          Enum.find(socket.assigns.resources, &(&1.id == String.to_integer(resource_id)))

        {
          :noreply,
          socket
          |> assign(selected_access_control: "resources")
          |> assign(show_resource_modal: true)
          |> assign(selected_record: resource)
          |> assign(modal_operation: operation)
        }
    end
  end

  @impl true
  def handle_event("validate_resource_form", %{"resource" => resource_params}, socket) do
    changeset =
      Resources.change_creation(%Resource{}, resource_params, validate_unique: false)

    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate), "resource")}
  end

  @impl true
  def handle_event("save_resource", %{"resource" => resource_params}, socket) do
    case Resources.save(socket.assigns.current_scope, resource_params) do
      {:ok, _resource} ->
        {:noreply,
         socket
         |> assign(resources: Resources.fetch_all(socket.assigns.current_scope))
         |> put_flash(:info, "Successfully created the resource")
         |> close_modal()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset, "resource")}

      {:error, :unauthorized} ->
        {:noreply, socket |> put_flash(:error, "You are not authorized to add a resource!")}

      {:error, _} ->
        render_default_form_error(socket, "adding", "resource")
    end
  end

  @impl true
  def handle_event("update_resource", %{"resource" => resource_params}, socket) do
    case Resources.update(
           socket.assigns.current_scope,
           socket.assigns.selected_record,
           resource_params
         ) do
      {:ok, _resource} ->
        {:noreply,
         socket
         |> assign(resources: Resources.fetch_all(socket.assigns.current_scope))
         |> put_flash(:info, "Successfully updated the resource")
         |> close_modal()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset, "resource")}

      {:error, :unauthorized} ->
        {:noreply, socket |> put_flash(:error, "You are not authorized to update a resource!")}

      {:error, _} ->
        render_default_form_error(socket, "updating", "resource")
    end
  end

  @impl true
  def handle_event("delete_resource", _params, socket) do
    case Resources.delete(socket.assigns.current_scope, socket.assigns.selected_record) do
      {:ok, _resource} ->
        {:noreply,
         socket
         |> assign(resources: Resources.fetch_all(socket.assigns.current_scope))
         |> put_flash(:info, "Successfully delete the resource")
         |> close_modal()}

      {:error, :unauthorized} ->
        {:noreply, socket |> put_flash(:error, "You are not authorized to delete a resource!")}

      {:error, _} ->
        render_default_form_error(socket, "deleting", "resource")
    end
  end

  @impl true
  def handle_event("close_resource_modal", _params, socket) do
    {
      :noreply,
      socket
      |> close_modal()
    }
  end

  # *********************************************************************************************
  # ------------------------------------ End of Resources Section -------------------------------
  # *********************************************************************************************

  defp assign_form(socket, %Ecto.Changeset{} = changeset, table) do
    form = to_form(changeset, as: table)
    assign(socket, form: form)
  end

  defp render_default_form_error(socket, operation, table) do
    {:noreply,
     socket
     |> put_flash(
       :error,
       "Oops! Something went wrong while #{operation} the #{table}. Try again later."
     )
     |> close_modal()}
  end

  defp close_modal(socket) do
    socket
    |> reset_states()
  end

  defp back_to_editing_role(socket) do
    changeset =
      Roles.change_creation(socket.assigns.selected_record, %{}, validate_unique: false)

    socket
    |> assign(modal_operation: "edit")
    |> assign_form(changeset, "role")
  end
end
