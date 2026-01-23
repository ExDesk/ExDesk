defmodule ExDeskWeb.TicketLiveSubtasksTest do
  use ExDeskWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  import ExDesk.AccountsFixtures
  import ExDesk.SupportFixtures

  alias ExDesk.Repo
  alias ExDesk.Support
  alias ExDesk.Support.Ticket

  describe "Ticket show subtasks" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "renders a sub-tasks section", %{conn: conn} do
      ticket = ticket_fixture(subject: "Parent Ticket")
      {:ok, _view, html} = live(conn, ~p"/tickets/#{ticket}")

      assert html =~ "Sub-tasks"
      assert html =~ "ticket-subtasks"
    end

    test "creates a sub-task from the show page", %{conn: conn, user: _user} do
      parent = ticket_fixture(subject: "Parent")
      {:ok, view, _html} = live(conn, ~p"/tickets/#{parent}")

      assert has_element?(view, "#add-subtask-button")

      _html =
        view
        |> element("#add-subtask-button")
        |> render_click()

      assert has_element?(view, "#subtask-form")

      _html =
        view
        |> form("#subtask-form", %{"ticket" => %{"subject" => "Child 1"}})
        |> render_submit()

      assert Repo.get_by(Ticket, subject: "Child 1", parent_id: parent.id)
      assert render(view) =~ "Child 1"

      child = Repo.get_by!(Ticket, subject: "Child 1", parent_id: parent.id)
      {:ok, _child_view, child_html} = live(conn, ~p"/tickets/#{child}")

      assert child_html =~ "Parent"
      assert child_html =~ "ticket-parent-link"
      assert child.parent_id == parent.id
      assert child.requester_id == parent.requester_id
      assert child.space_id == parent.space_id

      # also ensure direct API works for listing
      assert [%Ticket{} | _] = Support.list_subtasks(parent.id)
    end
  end
end
