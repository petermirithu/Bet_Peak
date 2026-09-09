defmodule BetPeak.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :msisdn, :string
    field :role, Ecto.Enum, values: [:admin, :user], default: :user
    field :is_superuser, :boolean, default: false
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :utc_datetime
    field :authenticated_at, :utc_datetime, virtual: true

    has_many :sports, BetPeak.Sports.Sport
    has_many :teams, BetPeak.Teams.Team
    has_many :games, BetPeak.Games.Game
    has_many :bets, BetPeak.Bets.Bet

    timestamps(type: :utc_datetime)
  end

  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:first_name, :last_name, :email, :msisdn, :password])
    |> validate_required([:first_name, :last_name, :email, :msisdn, :password])
    |> format_first_last_name()
    |> validate_length(:first_name, min: 3)
    |> validate_length(:last_name, min: 3)
    |> validate_length(:msisdn, min: 11, max: 15)
    |> validate_email(opts)
    |> unique_constraint(:email)
    |> unique_constraint(:msisdn)
    |> validate_password(opts)
  end

  def access_changeset(user, attrs) do
    user
    |> cast(attrs, [:role, :is_superuser])
    |> validate_required([:role, :is_superuser])
    |> validate_is_superuser()
  end

  defp validate_is_superuser(changeset) do
    role = get_field(changeset, :role)
    is_superuser = get_field(changeset, :is_superuser)

    if role && is_superuser && role == :user && is_superuser == true do
      add_error(changeset, :is_superuser, "A normal user can not be a super user!")
    else
      changeset
    end
  end

  defp format_first_last_name(changeset) do
    update_change(changeset, :first_name, &String.trim/1)
    update_change(changeset, :last_name, &String.trim/1)
  end

  @doc """
  A user changeset for registering or changing the email.

  It requires the email to change otherwise an error is added.

  ## Options

    * `:validate_unique` - Set to false if you don't want to validate the
      uniqueness of the email, useful when displaying live validations.
      Defaults to `true`.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
  end

  defp validate_email(changeset, opts) do
    changeset =
      changeset
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
        message: "must have the @ sign and no spaces"
      )
      |> validate_length(:email, max: 160)

    if Keyword.get(opts, :validate_unique, true) do
      changeset
      |> unsafe_validate_unique(:email, BetPeak.Repo)
      |> unique_constraint(:email)
      |> validate_email_changed()
    else
      changeset
    end
  end

  defp validate_email_changed(changeset) do
    if get_field(changeset, :email) && get_change(changeset, :email) == nil do
      add_error(changeset, :email, "did not change")
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the password.

  It is important to validate the length of the password, as long passwords may
  be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72)
    |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/,
      message: "at least one digit or punctuation character"
    )
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%BetPeak.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end
end
