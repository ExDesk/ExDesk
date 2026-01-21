defmodule ExDesk.SupportActivityTest do
  use ExDesk.DataCase

  import ExDesk.AccountsFixtures
  alias ExDesk.Support

  describe "recent activities" do
    test "list_recent_activities/1 returns empty list when no activities exist" do
      assert Support.list_recent_activities(limit: 5) == []
    end

    test "list_recent_activities/1 returns activities ordered by most recent first" do
      user = user_fixture()

      {:ok, ticket} =
        Support.create_ticket(%{
          subject: "Test Ticket",
          description: "Description",
          priority: "normal",
          status: "open",
          requester_id: user.id
        })

      {:ok, _} = Support.log_activity(ticket.id, user.id, :status_changed)
      Process.sleep(200)
      {:ok, _} = Support.log_activity(ticket.id, user.id, :commented)

      activities = Support.list_recent_activities(limit: 10)

      assert length(activities) >= 3
      [first, second | _rest] = activities
      assert first.action == :commented
      assert second.action == :status_changed
    end

    test "list_recent_activities/1 respects the limit option" do
      user = user_fixture()

      {:ok, ticket} =
        Support.create_ticket(%{
          subject: "Test Ticket",
          description: "Description",
          priority: "normal",
          status: "open",
          requester_id: user.id
        })

      {:ok, _} = Support.log_activity(ticket.id, user.id, :status_changed)
      Process.sleep(50)
      {:ok, _} = Support.log_activity(ticket.id, user.id, :commented)
      Process.sleep(50)
      {:ok, _} = Support.log_activity(ticket.id, user.id, :assigned)

      activities = Support.list_recent_activities(limit: 2)

      assert length(activities) == 2
    end
  end
end
