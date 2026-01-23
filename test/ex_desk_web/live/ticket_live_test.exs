defmodule ExDeskWeb.TicketLiveTest do
  use ExDeskWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ExDesk.AccountsFixtures
  import ExDesk.SupportFixtures

  describe "Index" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user)}
    end

    test "lists all tickets", %{conn: conn} do
      _ticket = ticket_fixture(subject: "Help me")
      {:ok, _index_live, html} = live(conn, ~p"/tickets")

      assert html =~ "Spaces"
      assert html =~ "New Ticket"
      assert html =~ "Help me"
    end

    test "displays tickets in a table with status badges", %{conn: conn} do
      ticket_fixture(subject: "Network Issue", status: :open, priority: :high)
      {:ok, _index_live, html} = live(conn, ~p"/tickets")

      # Should have table structure
      assert html =~ "<table"
      assert html =~ "Subject"
      assert html =~ "Status"
      assert html =~ "Priority"

      # Should have badge for status
      assert html =~ "badge"
      assert html =~ "Network Issue"
    end
  end

  describe "Show" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user)}
    end

    test "shows ticket details", %{conn: conn} do
      ticket = ticket_fixture(subject: "Detailed Issue", description: "This is a big problem")
      {:ok, _show_live, html} = live(conn, ~p"/tickets/#{ticket}")

      assert html =~ "Detailed Issue"
      assert html =~ "This is a big problem"
    end
  end

  describe "Create" do
    setup %{conn: conn} do
      user = user_fixture()
      space = space_fixture()

      %{conn: log_in_user(conn, user), user: user, space: space}
    end

    test "requires a space on create", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/tickets")

      {:ok, form_live, _html} =
        index_live
        |> element("a", "New Ticket")
        |> render_click()
        |> follow_redirect(conn, ~p"/tickets/new")

      assert has_element?(form_live, "#ticket_space_id")

      html =
        form_live
        |> form("#ticket-form", %{
          "ticket" => %{
            "subject" => "Missing Space",
            "description" => "Should fail",
            "priority" => "high"
          }
        })
        |> render_submit()

      assert has_element?(form_live, "#ticket-form")
      assert has_element?(form_live, "#ticket_space_id")
      assert html =~ "can&#39;t be blank"
      refute ExDesk.Repo.get_by(ExDesk.Support.Ticket, subject: "Missing Space")
    end

    test "creates a new ticket", %{conn: conn, space: space} do
      {:ok, index_live, _html} = live(conn, ~p"/tickets")

      {:ok, form_live, _html} =
        index_live
        |> element("a", "New Ticket")
        |> render_click()
        |> follow_redirect(conn, ~p"/tickets/new")

      assert render(form_live) =~ "New Ticket"

      _result =
        form_live
        |> form("#ticket-form", %{
          "ticket" => %{
            "space_id" => "#{space.id}",
            "subject" => "My Printer is Broken",
            "description" => "It makes a loud noise",
            "priority" => "high"
          }
        })
        |> render_submit()

      assert_patch(form_live, ~p"/tickets")

      # Verify it appears on index
      html = render(form_live)
      assert html =~ "My Printer is Broken"

      ticket = ExDesk.Repo.get_by!(ExDesk.Support.Ticket, subject: "My Printer is Broken")
      assert ticket.space_id == space.id
    end

    test "does not show assignee field for regular users", %{conn: conn, space: space} do
      {:ok, index_live, _html} = live(conn, ~p"/tickets")

      {:ok, form_live, _html} =
        index_live
        |> element("a", "New Ticket")
        |> render_click()
        |> follow_redirect(conn, ~p"/tickets/new")

      refute has_element?(form_live, "#ticket_assignee_id")

      _result =
        form_live
        |> form("#ticket-form", %{
          "ticket" => %{
            "space_id" => "#{space.id}",
            "subject" => "Untrusted Assignee",
            "description" => "Trying to forge assignee_id",
            "priority" => "high"
          }
        })
        |> render_submit()

      ticket = ExDesk.Repo.get_by!(ExDesk.Support.Ticket, subject: "Untrusted Assignee")
      assert is_nil(ticket.assignee_id)
    end

    test "updates ticket in listing", %{conn: conn} do
      agent = user_fixture(%{role: :agent})
      conn = log_in_user(conn, agent)

      ticket = ticket_fixture(subject: "Typo Subject")
      {:ok, index_live, _html} = live(conn, ~p"/tickets")

      {:ok, form_live, _html} =
        index_live
        # Need to add Edit link to index
        |> element("a", "Edit")
        |> render_click()
        |> follow_redirect(conn, ~p"/tickets/#{ticket}/edit")

      assert render(form_live) =~ "Edit Ticket"

      _result =
        form_live
        |> form("#ticket-form", %{
          "ticket" => %{"subject" => "Fixed Subject"}
        })
        |> render_submit()

      assert_patch(form_live, ~p"/tickets")

      html = render(form_live)
      assert html =~ "Fixed Subject"
    end
  end

  describe "Assign" do
    setup %{conn: conn} do
      agent = user_fixture(%{role: :agent})
      space = space_fixture()

      %{conn: log_in_user(conn, agent), agent: agent, space: space}
    end

    test "agent can assign a ticket on create", %{conn: conn, space: space} do
      assignee = user_fixture(%{role: :agent})

      {:ok, index_live, _html} = live(conn, ~p"/tickets")

      {:ok, form_live, _html} =
        index_live
        |> element("a", "New Ticket")
        |> render_click()
        |> follow_redirect(conn, ~p"/tickets/new")

      assert has_element?(form_live, "#ticket_assignee_id")

      _result =
        form_live
        |> form("#ticket-form", %{
          "ticket" => %{
            "space_id" => "#{space.id}",
            "subject" => "Assigned Ticket",
            "description" => "This ticket should be assigned",
            "priority" => "normal",
            "assignee_id" => "#{assignee.id}"
          }
        })
        |> render_submit()

      ticket = ExDesk.Repo.get_by!(ExDesk.Support.Ticket, subject: "Assigned Ticket")
      assert ticket.assignee_id == assignee.id
      assert ticket.space_id == space.id
    end
  end
end
