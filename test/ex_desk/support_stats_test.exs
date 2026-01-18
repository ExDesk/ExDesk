defmodule ExDesk.SupportStatsTest do
  use ExDesk.DataCase

  import ExDesk.AccountsFixtures
  alias ExDesk.Support

  describe "dashboard statistics" do
    test "count_total_tickets/0 returns the total number of tickets" do
      user = user_fixture()

      {:ok, _} =
        Support.create_ticket(%{
          subject: "T1",
          description: "D1",
          priority: "low",
          status: "open",
          requester_id: user.id
        })

      {:ok, _} =
        Support.create_ticket(%{
          subject: "T2",
          description: "D2",
          priority: "high",
          status: "closed",
          requester_id: user.id
        })

      {:ok, _} =
        Support.create_ticket(%{
          subject: "T3",
          description: "D3",
          priority: "normal",
          status: "solved",
          requester_id: user.id
        })

      assert Support.count_total_tickets() == 3
    end

    test "count_open_tickets/0 returns the count of tickets with status 'open'" do
      user = user_fixture()

      {:ok, _} =
        Support.create_ticket(%{
          subject: "T1",
          description: "D1",
          priority: "low",
          status: "open",
          requester_id: user.id
        })

      {:ok, _} =
        Support.create_ticket(%{
          subject: "T2",
          description: "D2",
          priority: "high",
          status: "closed",
          requester_id: user.id
        })

      {:ok, _} =
        Support.create_ticket(%{
          subject: "T3",
          description: "D3",
          priority: "normal",
          status: "open",
          requester_id: user.id
        })

      assert Support.count_open_tickets() == 2
    end

    test "count_assigned_tickets/1 returns the count of tickets assigned to a specific user" do
      user = user_fixture()
      assignee = user_fixture()

      {:ok, _} =
        Support.create_ticket(%{
          subject: "T1",
          description: "D1",
          priority: "low",
          status: "open",
          requester_id: user.id,
          assignee_id: assignee.id
        })

      {:ok, _} =
        Support.create_ticket(%{
          subject: "T2",
          description: "D2",
          priority: "high",
          status: "open",
          requester_id: user.id,
          assignee_id: assignee.id
        })

      # Unassigned
      {:ok, _} =
        Support.create_ticket(%{
          subject: "T3",
          description: "D3",
          priority: "normal",
          status: "open",
          requester_id: user.id
        })

      assert Support.count_assigned_tickets(assignee.id) == 2
    end

    test "calculate_avg_response_time/0 returns 0 when no tickets are solved" do
      assert Support.calculate_avg_response_time() == 0.0
    end
  end
end
