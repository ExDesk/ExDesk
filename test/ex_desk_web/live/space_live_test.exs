defmodule ExDeskWeb.SpaceLiveTest do
  use ExDeskWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ExDesk.AccountsFixtures
  import ExDesk.SupportFixtures

  alias ExDesk.Support

  describe "TemplateSelection with Live Preview" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user)}
    end

    test "shows template cards with first one selected by default", %{conn: conn} do
      {:ok, _live, html} = live(conn, ~p"/spaces/new")

      assert html =~ "Choose a template"
      # First template (Kanban) should be selected by default
      assert html =~ "selected"
      assert html =~ "Kanban"
    end

    test "clicking a template selects it and shows preview", %{conn: conn} do
      {:ok, live, _html} = live(conn, ~p"/spaces/new")

      # Click on Service Desk template
      html = live |> element("#template-service_desk") |> render_click()

      # Should now show Service Desk as selected
      assert html =~ "Service Desk"
      # Should show live preview for service desk
      assert html =~ "live-preview"
    end

    test "shows different preview for each template", %{conn: conn} do
      {:ok, live, _html} = live(conn, ~p"/spaces/new")

      # Kanban preview should show columns
      html = render(live)
      assert html =~ "To Do" or html =~ "In progress" or html =~ "Done"

      # Switch to Project
      html = live |> element("#template-project") |> render_click()
      assert html =~ "Project"
    end

    test "selected template navigates to form on continue", %{conn: conn} do
      {:ok, live, _html} = live(conn, ~p"/spaces/new")

      # Select service_desk and continue
      live |> element("#template-service_desk") |> render_click()

      {:ok, _form_live, html} =
        live
        |> element("a", "Continue")
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ "New Space"
    end
  end

  describe "Index" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user)}
    end

    test "lists all spaces", %{conn: conn} do
      _space = space_fixture(name: "IT Support", key: "IT")
      {:ok, _index_live, html} = live(conn, ~p"/spaces")

      assert html =~ "Spaces"
      assert html =~ "IT Support"
    end

    test "shows empty state when no spaces", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/spaces")

      assert html =~ "No spaces yet"
    end

    test "deletes space", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      space = space_fixture(name: "To Delete", key: "DEL", created_by_id: user.id)
      {:ok, index_live, _html} = live(conn, ~p"/spaces")

      assert index_live |> element("#space-#{space.id}") |> has_element?()

      index_live
      |> element("#space-#{space.id} button[phx-click=\"delete\"]")
      |> render_click()

      refute index_live |> element("#space-#{space.id}") |> has_element?()
    end
  end

  describe "Form" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user)}
    end

    test "creates space with valid data", %{conn: conn} do
      {:ok, form_live, _html} = live(conn, ~p"/spaces/new/service_desk")

      # Trigger name change to generate suggestions
      form_live
      |> form("#space-form", %{"space" => %{"name" => "IT Helpdesk"}})
      |> render_change()

      # Now select the key from the select field.
      # "IT Helpdesk" should generate "IH" as a suggestion.
      form_live
      |> form("#space-form", %{
        "space" => %{
          "key" => "IH"
        }
      })
      |> render_submit()

      assert_redirect(form_live, ~p"/spaces/IH")
    end

    test "shows validation errors", %{conn: conn} do
      {:ok, form_live, _html} = live(conn, ~p"/spaces/new/kanban")

      html =
        form_live
        |> form("#space-form", %{
          "space" => %{"name" => "", "key" => ""}
        })
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end
  end

  describe "Show" do
    setup %{conn: conn} do
      user = user_fixture()
      space = space_fixture(name: "My Space", key: "MYSP", created_by_id: user.id)
      %{conn: log_in_user(conn, user), space: space}
    end

    test "displays space details", %{conn: conn, space: space} do
      {:ok, _show_live, html} = live(conn, ~p"/spaces/#{space.key}")

      assert html =~ "My Space"
      assert html =~ "MYSP"
    end

    test "navigates to edit", %{conn: conn, space: space} do
      {:ok, show_live, _html} = live(conn, ~p"/spaces/#{space.key}")

      {:ok, _edit_live, html} =
        show_live
        |> element("a", "Edit")
        |> render_click()
        |> follow_redirect(conn, ~p"/spaces/#{space.key}/edit")

      assert html =~ "Edit Space"
    end
  end

  describe "Authorization" do
    setup %{conn: conn} do
      owner = user_fixture()
      other_user = user_fixture()
      space = space_fixture(name: "Owned Space", key: "OWN", created_by_id: owner.id)

      %{conn: log_in_user(conn, other_user), space: space}
    end

    test "non-owner cannot access edit", %{conn: conn, space: space} do
      assert {:error, {:redirect, %{to: _to}}} = live(conn, ~p"/spaces/#{space.key}/edit")
    end

    test "non-owner does not see edit/delete buttons", %{conn: conn, space: space} do
      {:ok, view, _html} = live(conn, ~p"/spaces/#{space.key}")
      refute has_element?(view, "a", "Edit")
      refute has_element?(view, "button", "Delete")
    end
  end

  describe "Show (kanban)" do
    setup %{conn: conn} do
      user = user_fixture()
      space = space_fixture(template: :kanban)

      %{conn: log_in_user(conn, user), user: user, space: space}
    end

    test "renders kanban columns and distributes tickets by status", %{
      conn: conn,
      user: user,
      space: space
    } do
      assert {:ok, todo_ticket} =
               Support.create_ticket_in_space(
                 space.id,
                 %{subject: "Todo", requester_id: user.id, status: :open, priority: :high},
                 user.id
               )

      assert {:ok, doing_ticket} =
               Support.create_ticket_in_space(
                 space.id,
                 %{
                   subject: "In progress",
                   requester_id: user.id,
                   status: :pending,
                   priority: :normal
                 },
                 user.id
               )

      assert {:ok, done_ticket} =
               Support.create_ticket_in_space(
                 space.id,
                 %{subject: "Done", requester_id: user.id, status: :solved, priority: :low},
                 user.id
               )

      {:ok, view, _html} = live(conn, ~p"/spaces/#{space.key}")

      assert has_element?(view, "#kanban-board")
      assert has_element?(view, "#kanban-col-todo")
      assert has_element?(view, "#kanban-col-doing")
      assert has_element?(view, "#kanban-col-done")

      assert has_element?(view, "#kanban-col-todo #kanban-ticket-#{todo_ticket.id}")
      assert has_element?(view, "#kanban-col-doing #kanban-ticket-#{doing_ticket.id}")
      assert has_element?(view, "#kanban-col-done #kanban-ticket-#{done_ticket.id}")
    end

    test "creates a new ticket in the space", %{conn: conn, user: _user, space: space} do
      {:ok, view, _html} = live(conn, ~p"/spaces/#{space.key}")

      view |> element("#space-new-ticket") |> render_click()

      assert has_element?(view, "#space-ticket-form")

      view
      |> form("#space-ticket-form", %{
        "ticket" => %{
          "subject" => "From Space",
          "description" => "Created from kanban",
          "priority" => "high"
        }
      })
      |> render_submit()

      ticket =
        space.id
        |> Support.list_tickets_by_space()
        |> Enum.find(fn t -> t.subject == "From Space" end)

      assert ticket
      assert has_element?(view, "#kanban-col-todo #kanban-ticket-#{ticket.id}")
    end
  end

  describe "Show (kanban) filters" do
    setup %{conn: conn} do
      user = user_fixture()
      space = space_fixture(template: :kanban)

      %{conn: log_in_user(conn, user), user: user, space: space}
    end

    test "filters by priority via query params", %{conn: conn, user: user, space: space} do
      assert {:ok, high} =
               Support.create_ticket_in_space(
                 space.id,
                 %{subject: "High prio", requester_id: user.id, status: :open, priority: :high},
                 user.id
               )

      assert {:ok, low} =
               Support.create_ticket_in_space(
                 space.id,
                 %{subject: "Low prio", requester_id: user.id, status: :open, priority: :low},
                 user.id
               )

      {:ok, view, _html} = live(conn, ~p"/spaces/#{space.key}?#{%{priority: "high"}}")

      assert has_element?(view, "#kanban-ticket-#{high.id}")
      refute has_element?(view, "#kanban-ticket-#{low.id}")
    end

    test "filters by key search via query params", %{conn: conn, user: user, space: space} do
      assert {:ok, ticket} =
               Support.create_ticket_in_space(
                 space.id,
                 %{subject: "Search me", requester_id: user.id, status: :open, priority: :normal},
                 user.id
               )

      {:ok, view, _html} =
        live(conn, ~p"/spaces/#{space.key}?#{%{q: "#{space.key}-#{ticket.id}"}}")

      assert has_element?(view, "#kanban-ticket-#{ticket.id}")
    end
  end

  describe "Show (kanban) assignee" do
    setup %{conn: conn} do
      agent = user_fixture(%{role: :agent})
      assignee = user_fixture(%{role: :agent})
      space = space_fixture(template: :kanban)

      %{conn: log_in_user(conn, agent), agent: agent, assignee: assignee, space: space}
    end

    test "agent can assign a new ticket in the space", %{
      conn: conn,
      assignee: assignee,
      space: space
    } do
      {:ok, view, _html} = live(conn, ~p"/spaces/#{space.key}")

      view |> element("#space-new-ticket") |> render_click()

      assert has_element?(view, "#space-ticket-form")
      assert has_element?(view, "#ticket_assignee_id")

      view
      |> form("#space-ticket-form", %{
        "ticket" => %{
          "subject" => "Assigned from Space",
          "description" => "Created from kanban",
          "priority" => "high",
          "assignee_id" => "#{assignee.id}"
        }
      })
      |> render_submit()

      ticket = ExDesk.Repo.get_by!(Support.Ticket, subject: "Assigned from Space")
      assert ticket.space_id == space.id
      assert ticket.assignee_id == assignee.id
    end
  end

  describe "Show (service desk)" do
    setup %{conn: conn} do
      user = user_fixture(%{role: :user})
      other = user_fixture(%{role: :user})
      space = space_fixture(template: :service_desk)

      assert {:ok, my_ticket} =
               Support.create_ticket_in_space(
                 space.id,
                 %{subject: "Mine", requester_id: user.id, status: :open, priority: :normal},
                 user.id
               )

      assert {:ok, other_ticket} =
               Support.create_ticket_in_space(
                 space.id,
                 %{subject: "Other", requester_id: other.id, status: :open, priority: :normal},
                 other.id
               )

      %{
        conn: log_in_user(conn, user),
        user: user,
        space: space,
        my_ticket: my_ticket,
        other_ticket: other_ticket
      }
    end

    test "end user only sees their own tickets", %{
      conn: conn,
      space: space,
      my_ticket: my_ticket,
      other_ticket: other_ticket
    } do
      {:ok, view, _html} = live(conn, ~p"/spaces/#{space.key}")

      assert has_element?(view, "#service-desk-tickets")
      assert has_element?(view, "#space-ticket-#{my_ticket.id}")
      refute has_element?(view, "#space-ticket-#{other_ticket.id}")
    end

    test "agent sees all tickets in space", %{
      space: space,
      my_ticket: my_ticket,
      other_ticket: other_ticket
    } do
      agent = user_fixture(%{role: :agent})

      {:ok, view, _html} = live(log_in_user(build_conn(), agent), ~p"/spaces/#{space.key}")

      assert has_element?(view, "#service-desk-tickets")
      assert has_element?(view, "#space-ticket-#{my_ticket.id}")
      assert has_element?(view, "#space-ticket-#{other_ticket.id}")
    end

    test "filters by status via query params", %{space: space, user: user} do
      assert {:ok, solved_ticket} =
               Support.create_ticket_in_space(
                 space.id,
                 %{subject: "Solved", requester_id: user.id, status: :solved, priority: :normal},
                 user.id
               )

      agent = user_fixture(%{role: :agent})
      conn = log_in_user(build_conn(), agent)

      {:ok, view, _html} = live(conn, ~p"/spaces/#{space.key}?#{%{status: "solved"}}")

      assert has_element?(view, "#space-ticket-#{solved_ticket.id}")
    end
  end
end
