defmodule BetPeak.Permissions do
  import Ecto.Query, warn: false

  alias BetPeak.Repo
  alias BetPeak.Permissions.Permission
  alias BetPeak.Accounts.Scope
  alias BetPeak.Authorization

  def save(%Scope{} = current_scope, attrs) do
    case Authorization.authorize!(current_scope, "Access Control", "create") do
      :ok ->
        %Permission{}
        |> Permission.changeset(attrs, [])
        |> Repo.insert()

      :unauthorized ->
        {:error, :unauthorized}
    end
  end

  def fetch_all(%Scope{} = current_scope) do
    case Authorization.authorize!(current_scope, "Access Control", "read") do
      :ok ->
        from(permission in Permission,
          preload: [:resource],
          order_by: [desc: permission.resource_id, asc: permission.inserted_at]
        )
        |> Repo.all()

      :unauthorized ->
        []
    end
  end

  def change_creation(permission, attrs \\ %{}, opts \\ []) do
    Permission.changeset(permission, attrs, opts)
  end

  def update(%Scope{} = current_scope, permission, attrs) do
    case Authorization.authorize!(current_scope, "Access Control", "update") do
      :ok ->
        permission
        |> Permission.changeset(attrs, [])
        |> Repo.update()

      :unauthorized ->
        {:error, :unauthorized}
    end
  end

  def delete(%Scope{} = current_scope, %Permission{} = permission) do
    case Authorization.authorize!(current_scope, "Access Control", "delete") do
      :ok ->
        Repo.delete(permission)

      :unauthorized ->
        {:error, :unauthorized}
    end
  end
end
