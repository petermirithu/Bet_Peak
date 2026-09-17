defmodule BetPeak.RoleInherits do
  import Ecto.Query, warn: false

  alias BetPeak.Repo
  alias BetPeak.RoleInherits.RoleInherit
  alias BetPeak.Authorization
  alias BetPeak.Accounts.Scope

  def save(%Scope{} = current_scope, attrs) do
    case Authorization.authorize!(current_scope, "Access Control", "create") do
      :ok ->
        %RoleInherit{}
        |> RoleInherit.changeset(attrs, [])
        |> Repo.insert()

      :unauthorized ->
        {:error, :unauthorized}
    end
  end

  def change_creation(role_inherit, attrs \\ %{}, opts \\ []) do
    RoleInherit.changeset(role_inherit, attrs, opts)
  end

  def delete(%Scope{} = current_scope, %RoleInherit{} = role_inherit) do
    case Authorization.authorize!(current_scope, "Access Control", "delete") do
      :ok ->
        role_inherit
        |> Repo.delete()

      :unauthorized ->
        {:error, :unauthorized}
    end
  end
end
