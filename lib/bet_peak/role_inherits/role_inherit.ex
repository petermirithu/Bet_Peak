defmodule BetPeak.RoleInherits.RoleInherit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "role_inherits" do
    belongs_to :parent_role, BetPeak.Roles.Role
    belongs_to :child_role, BetPeak.Roles.Role

    timestamps(type: :utc_datetime)
  end

  def changeset(role_inherit, attrs, _opts) do
    role_inherit
    |> cast(attrs, [:parent_role_id, :child_role_id])
    |> validate_required([:parent_role_id, :child_role_id])
    |> foreign_key_constraint(:parent_role_id)
    |> foreign_key_constraint(:child_role_id)
    |> validate_parent_child_role()
    |> unique_constraint([:parent_role_id, :child_role_id])
  end

  defp validate_parent_child_role(changeset) do
    parent_role_id = get_field(changeset, :parent_role_id)

    case get_field(changeset, :child_role_id) do
      ^parent_role_id when not is_nil(parent_role_id) ->
        add_error(
          changeset,
          :parent_role_id,
          "Parent Role can not be the same role"
        )

      _ ->
        changeset
    end
  end
end
