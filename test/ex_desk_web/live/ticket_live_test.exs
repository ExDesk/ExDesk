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
      ticket = ticket_fixture(subject: "Help me")
      {:ok, _index_live, html} = live(conn, ~p"/tickets")

      assert html =~ "Tickets"
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
      %{conn: log_in_user(conn, user)}
    end

    test "creates a new ticket", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/tickets")

      {:ok, form_live, _html} =
        index_live
        |> element("a", "New Ticket")
        |> render_click()
        |> follow_redirect(conn, ~p"/tickets/new")

      assert render(form_live) =~ "New Ticket"

      result =
        form_live
        |> form("#ticket-form", %{
          "ticket" => %{
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
    end

    test "updates ticket in listing", %{conn: conn} do
      ticket = ticket_fixture(subject: "Typo Subject")
      {:ok, index_live, _html} = live(conn, ~p"/tickets")

      {:ok, form_live, _html} =
        index_live
        # Need to add Edit link to index
        |> element("a", "Edit")
        |> render_click()
        |> follow_redirect(conn, ~p"/tickets/#{ticket}/edit")

      assert render(form_live) =~ "Edit Ticket"

      result =
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
end
