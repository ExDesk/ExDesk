defmodule ExDeskWeb.DashboardLiveTest do
  use ExDeskWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ExDesk.AccountsFixtures
  import ExDesk.SupportFixtures

  alias ExDesk.Support

  describe "Dashboard" do
    test "shows global stats and computed assigned/high priority", %{conn: conn} do
      agent = user_fixture(%{role: :agent})
      requester = user_fixture(%{role: :user})
      conn = log_in_user(conn, agent)

      # Active assigned to current agent
      _t1 =
        ticket_fixture(%{
          requester_id: requester.id,
          assignee_id: agent.id,
          status: :open,
          priority: :high
        })

      _t2 =
        ticket_fixture(%{
          requester_id: requester.id,
          assignee_id: agent.id,
          status: :pending,
          priority: :urgent
        })

      # Not active
      _t3 =
        ticket_fixture(%{
          requester_id: requester.id,
          assignee_id: agent.id,
          status: :solved,
          priority: :high
        })

      {:ok, view, html} = live(conn, ~p"/dashboard")

      assert html =~ "Dashboard"
      assert html =~ "Total Tickets"
      assert html =~ "Active Tickets"
      assert html =~ "Assigned to Me"

      # Prefer element IDs for stable assertions
      assert has_element?(view, "#stat-total-tickets")
      assert has_element?(view, "#stat-active-tickets")
      assert has_element?(view, "#stat-assigned-to-me")

      # Sanity check: assigned active count and high priority count match context functions
      assert html =~ Integer.to_string(Support.count_assigned_active_tickets(agent.id))

      assert html =~
               Integer.to_string(Support.count_assigned_active_high_priority_tickets(agent.id))
    end

    test "recent activity items link to ticket", %{conn: conn} do
      agent = user_fixture(%{role: :agent})
      requester = user_fixture(%{role: :user})
      conn = log_in_user(conn, agent)

      ticket = ticket_fixture(%{requester_id: requester.id, status: :open})
      _comment = comment_fixture(%{ticket_id: ticket.id, author_id: agent.id, body: "Looking"})

      [activity] = Support.list_recent_activities(limit: 1)

      {:ok, view, _html} = live(conn, ~p"/dashboard")

      assert has_element?(view, "#dashboard-activity-feed")

      assert has_element?(view, "#activity-#{activity.id}")

      assert has_element?(
               view,
               "#activity-#{activity.id}[href=\"/tickets/#{ticket.id}?return_to=/dashboard\"]"
             )

      assert has_element?(view, "#activity-#{activity.id}", agent.email)
    end
  end
end
