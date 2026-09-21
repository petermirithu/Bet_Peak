defmodule BetPeak.AuthorizationTest do
  use BetPeak.DataCase

  describe "authorization" do
    alias BetPeak.Authorization

    import BetPeak.AccountsFixtures,
      only: [
        user_scope_fixture: 0,
        super_admin_scope_fixture: 0,
        admin_scope_fixture: 0
      ]

    alias BetPeak.AccessControlFixtures

    setup do
      AccessControlFixtures.setup_roles()

      %{
        super_admin_scope: super_admin_scope_fixture(),
        admin_scope: admin_scope_fixture(),
        user_scope: user_scope_fixture()
      }
    end

    test "authorize!/2 return :ok for authorized user", context do
      assert :ok = Authorization.authorize!(context.super_admin_scope, "Access Control", "read")
    end

    test "authorize!/2 return :unauthorized for un authorized user", context do
      assert :unauthorized =
               Authorization.authorize!(context.admin_scope, "Access Control", "read")
    end

    test "authorize!/2 return :unauthorized with bad attributes", context do
      assert :unauthorized =
               Authorization.authorize!(
                 context.admin_scope,
                 "Resource does not exist",
                 "never write"
               )
    end
  end
end
