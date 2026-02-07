defmodule ExDeskWeb.SpaceLiveKanbanDnDTest do
  use ExDeskWeb.ConnCase

  import Phoenix.LiveViewTest
  import ExDesk.AccountsFixtures
  import ExDesk.SupportFixtures

  alias ExDesk.Repo
  alias ExDesk.Support
  alias ExDesk.Support.Ticket

  describe "Show (kanban dnd)" do
    setup %{conn: conn} do
      user = user_fixture(%{role: :agent})
      space = space_fixture(template: :kanban)

      %{conn: log_in_user(conn, user), user: user, space: space}
    end

    test "moves a ticket between columns via kanban_drop event", %{
      conn: conn,
      user: user,
      space: space
    } do
      assert {:ok, t1} =
               Support.create_ticket_in_space(
                 space.id,
                 %{subject: "One", requester_id: user.id, status: :open},
                 user.id
               )

      {:ok, view, _html} = live(conn, ~p"/spaces/#{space.key}")

      assert has_element?(view, "#kanban-ticket-#{t1.id}")

      _html =
        render_hook(view, "kanban_drop", %{
          "ticket_id" => "#{t1.id}",
          "from_column" => "todo",
          "to_column" => "done",
          "from_ordered_ids" => [],
          "to_ordered_ids" => ["#{t1.id}"]
        })

      assert has_element?(view, "#kanban-col-done #kanban-ticket-#{t1.id}")
    end

    test "users cannot move tickets via kanban_drop", %{space: space, conn: conn} do
      requester = user_fixture(%{role: :user})
      conn = log_in_user(conn, requester)

      assert {:ok, t1} =
               Support.create_ticket_in_space(
                 space.id,
                 %{subject: "One", requester_id: requester.id, status: :open},
                 requester.id
               )

      {:ok, view, _html} = live(conn, ~p"/spaces/#{space.key}")

      assert has_element?(view, "#kanban-col-todo #kanban-ticket-#{t1.id}")

      _html =
        render_hook(view, "kanban_drop", %{
          "ticket_id" => "#{t1.id}",
          "from_column" => "todo",
          "to_column" => "done",
          "from_ordered_ids" => [],
          "to_ordered_ids" => ["#{t1.id}"]
        })

      assert has_element?(view, "#kanban-ticket-#{t1.id}")
      assert render(view) =~ "not authorized"

      updated = Repo.get!(Ticket, t1.id)
      assert updated.status == :open
    end
  end
end
