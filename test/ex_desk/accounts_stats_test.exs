defmodule ExDesk.AccountsStatsTest do
  use ExDesk.DataCase

  import ExDesk.AccountsFixtures
  alias ExDesk.Accounts

  describe "user statistics" do
    test "count_users/0 returns the total number of users" do
      user_fixture()
      user_fixture()
      user_fixture()

      assert Accounts.count_users() == 3
    end

    test "count_users/0 returns 0 when no users exist" do
      assert Accounts.count_users() == 0
    end
  end
end
