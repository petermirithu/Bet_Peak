defmodule BetPeak.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BetPeak.Accounts` context.
  """
  use BetPeakWeb.ConnCase, async: true

  import Ecto.Query

  alias BetPeak.Accounts
  alias BetPeak.Accounts.Scope
  alias BetPeak.AccessControlFixtures

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello@worlD12"
  def valid_first_name, do: "Pyra"
  def valid_last_name, do: "Myra"
  def unique_user_msisdn, do: "+254#{Enum.random(100_000_000..999_999_999)}"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email()
    })
  end

  def unconfirmed_user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Accounts.register_user()

    user
  end

  def user_scope_fixture do
    user = user_fixture()
    user_scope_fixture(user)
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        first_name: valid_first_name(),
        last_name: valid_last_name(),
        msisdn: unique_user_msisdn(),
        email: unique_user_email(),
        password: valid_user_password()
      })
      |> Accounts.register_user()

    user
  end

  def super_admin_scope_fixture do
    user_fixture()
    |> AccessControlFixtures.convert_user_to_admin("Super Admin")
    |> user_scope_fixture()
  end

  def admin_scope_fixture do
    user_fixture()
    |> AccessControlFixtures.convert_user_to_admin("Admin")
    |> user_scope_fixture()
  end

  def user_scope_fixture(user) do
    Scope.for_user(user)
  end

  def set_password(user) do
    {:ok, {user, _expired_tokens}} =
      Accounts.update_user_password(user, %{password: valid_user_password()})

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def override_token_authenticated_at(token, authenticated_at) when is_binary(token) do
    BetPeak.Repo.update_all(
      from(t in Accounts.UserToken,
        where: t.token == ^token
      ),
      set: [authenticated_at: authenticated_at]
    )
  end

  def generate_user_magic_link_token(user) do
    {encoded_token, user_token} = Accounts.UserToken.build_email_token(user, "login")
    BetPeak.Repo.insert!(user_token)
    {encoded_token, user_token.token}
  end

  def offset_user_token(token, amount_to_add, unit) do
    dt = DateTime.add(DateTime.utc_now(:second), amount_to_add, unit)

    BetPeak.Repo.update_all(
      from(ut in Accounts.UserToken, where: ut.token == ^token),
      set: [inserted_at: dt, authenticated_at: dt]
    )
  end
end
