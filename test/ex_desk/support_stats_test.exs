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

    test "count_active_tickets/0 returns the count of active tickets" do
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
          status: "pending",
          requester_id: user.id
        })

      {:ok, _} =
        Support.create_ticket(%{
          subject: "T3",
          description: "D3",
          priority: "normal",
          status: "on_hold",
          requester_id: user.id
        })

      # open + pending + on_hold are considered active
      assert Support.count_active_tickets() == 3
    end

    test "count_assigned_active_tickets/1 returns the count of active tickets assigned to a user" do
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
          status: "pending",
          requester_id: user.id,
          assignee_id: assignee.id
        })

      # Solved should not count as active
      {:ok, _} =
        Support.create_ticket(%{
          subject: "T4",
          description: "D4",
          priority: "normal",
          status: "solved",
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

      assert Support.count_assigned_active_tickets(assignee.id) == 2
    end

    test "count_assigned_active_high_priority_tickets/1 counts only high/urgent active tickets" do
      requester = user_fixture()
      assignee = user_fixture(%{role: :agent})

      {:ok, _} =
        Support.create_ticket(%{
          subject: "Normal",
          description: "D1",
          priority: "normal",
          status: "open",
          requester_id: requester.id,
          assignee_id: assignee.id
        })

      {:ok, _} =
        Support.create_ticket(%{
          subject: "High",
          description: "D2",
          priority: "high",
          status: "open",
          requester_id: requester.id,
          assignee_id: assignee.id
        })

      {:ok, _} =
        Support.create_ticket(%{
          subject: "Urgent",
          description: "D3",
          priority: "urgent",
          status: "pending",
          requester_id: requester.id,
          assignee_id: assignee.id
        })

      {:ok, _} =
        Support.create_ticket(%{
          subject: "Closed high",
          description: "D4",
          priority: "high",
          status: "closed",
          requester_id: requester.id,
          assignee_id: assignee.id
        })

      assert Support.count_assigned_active_high_priority_tickets(assignee.id) == 2
    end

    test "calculate_avg_response_time/0 returns nil when there are no agent responses" do
      assert is_nil(Support.calculate_avg_response_time())
    end

    test "calculate_avg_response_time/0 averages time to first agent/admin public comment (hours)" do
      requester = user_fixture()
      agent = user_fixture(%{role: :agent})

      {:ok, ticket} =
        Support.create_ticket(%{
          subject: "T1",
          description: "D1",
          priority: "normal",
          status: "open",
          requester_id: requester.id
        })

      one_hour_ago =
        DateTime.utc_now() |> DateTime.add(-3600, :second) |> DateTime.truncate(:second)

      ticket =
        ticket
        |> Ecto.Changeset.change(inserted_at: one_hour_ago)
        |> Repo.update!()

      {:ok, _comment} =
        Support.add_comment(ticket.id, agent.id, %{body: "We are looking into it"})

      avg = Support.calculate_avg_response_time()
      assert is_float(avg)
      assert_in_delta avg, 1.0, 0.1
    end
  end
end
