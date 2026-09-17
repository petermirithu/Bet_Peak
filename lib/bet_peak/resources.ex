defmodule BetPeak.Resources do
  import Ecto.Query, warn: false

  alias BetPeak.Repo
  alias BetPeak.Resources.Resource
  alias BetPeak.Accounts.Scope
  alias BetPeak.Authorization

  def save(%Scope{} = current_scope, attrs) do
    case Authorization.authorize!(current_scope, "Access Control", "create") do
      :ok ->
        %Resource{}
        |> Resource.changeset(attrs, [])
        |> Repo.insert()

      :unauthorized ->
        {:error, :unauthorized}
    end
  end

  def fetch_all(%Scope{} = current_scope) do
    case Authorization.authorize!(current_scope, "Access Control", "read") do
      :ok ->
        from(resource in Resource,
          order_by: [desc: resource.inserted_at]
        )
        |> Repo.all()

      :unauthorized ->
        []
    end
  end

  def change_creation(resource, attrs \\ %{}, opts \\ []) do
    Resource.changeset(resource, attrs, opts)
  end

  def update(%Scope{} = current_scope, resource, attrs) do
    case Authorization.authorize!(current_scope, "Access Control", "update") do
      :ok ->
        resource
        |> Resource.changeset(attrs, [])
        |> Repo.update()

      :unauthorized ->
        {:error, :unauthorized}
    end
  end

  def delete(%Scope{} = current_scope, %Resource{} = resource) do
    case Authorization.authorize!(current_scope, "Access Control", "delete") do
      :ok ->
        Repo.delete(resource)

      :unauthorized ->
        {:error, :unauthorized}
    end
  end
end
