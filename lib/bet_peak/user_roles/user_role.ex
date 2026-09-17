defmodule BetPeak.UserRoles.UserRole do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_roles" do
    belongs_to :user, BetPeak.Accounts.User
    belongs_to :role, BetPeak.Roles.Role

    timestamps(type: :utc_datetime)
  end

  def changeset(user_role, attrs, _opts) do
    user_role
    |> cast(attrs, [:role_id, :user_id])
    |> validate_required([:user_id, :role_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:role_id)
    |> unique_constraint([:role_id, :user_id])
  end
end
