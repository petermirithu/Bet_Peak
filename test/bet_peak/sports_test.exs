defmodule BetPeak.SportsTest do
  use BetPeak.DataCase

  alias BetPeak.Sports

  describe "sports" do
    alias BetPeak.Sports.Sport

    import BetPeak.AccountsFixtures, only: [user_scope_fixture: 0]
    import BetPeak.SportsFixtures

    @invalid_attrs %{active: nil, name: nil, description: nil, slug: nil}

    test "list_sports/1 returns all scoped sports" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      sport = sport_fixture(scope)
      other_sport = sport_fixture(other_scope)
      assert Sports.list_sports(scope) == [sport]
      assert Sports.list_sports(other_scope) == [other_sport]
    end

    test "get_sport!/2 returns the sport with given id" do
      scope = user_scope_fixture()
      sport = sport_fixture(scope)
      other_scope = user_scope_fixture()
      assert Sports.get_sport!(scope, sport.id) == sport
      assert_raise Ecto.NoResultsError, fn -> Sports.get_sport!(other_scope, sport.id) end
    end

    test "create_sport/2 with valid data creates a sport" do
      valid_attrs = %{active: true, name: "some name", description: "some description", slug: "some slug"}
      scope = user_scope_fixture()

      assert {:ok, %Sport{} = sport} = Sports.create_sport(scope, valid_attrs)
      assert sport.active == true
      assert sport.name == "some name"
      assert sport.description == "some description"
      assert sport.slug == "some slug"
      assert sport.user_id == scope.user.id
    end

    test "create_sport/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Sports.create_sport(scope, @invalid_attrs)
    end

    test "update_sport/3 with valid data updates the sport" do
      scope = user_scope_fixture()
      sport = sport_fixture(scope)
      update_attrs = %{active: false, name: "some updated name", description: "some updated description", slug: "some updated slug"}

      assert {:ok, %Sport{} = sport} = Sports.update_sport(scope, sport, update_attrs)
      assert sport.active == false
      assert sport.name == "some updated name"
      assert sport.description == "some updated description"
      assert sport.slug == "some updated slug"
    end

    test "update_sport/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      sport = sport_fixture(scope)

      assert_raise MatchError, fn ->
        Sports.update_sport(other_scope, sport, %{})
      end
    end

    test "update_sport/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      sport = sport_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Sports.update_sport(scope, sport, @invalid_attrs)
      assert sport == Sports.get_sport!(scope, sport.id)
    end

    test "delete_sport/2 deletes the sport" do
      scope = user_scope_fixture()
      sport = sport_fixture(scope)
      assert {:ok, %Sport{}} = Sports.delete_sport(scope, sport)
      assert_raise Ecto.NoResultsError, fn -> Sports.get_sport!(scope, sport.id) end
    end

    test "delete_sport/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      sport = sport_fixture(scope)
      assert_raise MatchError, fn -> Sports.delete_sport(other_scope, sport) end
    end

    test "change_sport/2 returns a sport changeset" do
      scope = user_scope_fixture()
      sport = sport_fixture(scope)
      assert %Ecto.Changeset{} = Sports.change_sport(scope, sport)
    end
  end
end
