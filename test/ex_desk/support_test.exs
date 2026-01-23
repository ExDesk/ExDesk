defmodule ExDesk.SupportTest do
  use ExDesk.DataCase

  alias ExDesk.Support
  alias ExDesk.Support.Ticket

  import ExDesk.SupportFixtures
  import ExDesk.AccountsFixtures

  describe "groups" do
    @invalid_attrs %{name: nil}

    test "list_groups/0 returns all groups" do
      group = group_fixture()
      assert Support.list_groups() == [group]
    end

    test "get_group!/1 returns the group with given id" do
      group = group_fixture()
      assert Support.get_group!(group.id) == group
    end

    test "create_group/1 with valid data creates a group" do
      valid_attrs = %{name: "some name", description: "some description"}
      assert {:ok, %ExDesk.Support.Group{} = group} = Support.create_group(valid_attrs)
      assert group.name == "some name"
      assert group.description == "some description"
    end

    test "create_group/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Support.create_group(@invalid_attrs)
    end

    test "update_group/2 with valid data updates the group" do
      group = group_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %ExDesk.Support.Group{} = group} = Support.update_group(group, update_attrs)
      assert group.name == "some updated name"
    end

    test "delete_group/1 deletes the group" do
      group = group_fixture()
      assert {:ok, %ExDesk.Support.Group{}} = Support.delete_group(group)
      assert_raise Ecto.NoResultsError, fn -> Support.get_group!(group.id) end
    end
  end

  describe "tickets" do
    test "create_ticket/2 with valid data creates a ticket" do
      user = user_fixture()
      valid_attrs = %{subject: "Help me", description: "Issue", requester_id: user.id}

      assert {:ok, %Ticket{} = ticket} = Support.create_ticket(valid_attrs)
      assert ticket.subject == "Help me"
      assert ticket.status == :open
    end

    test "create_ticket_in_space/3 sets space_id" do
      space = space_fixture(template: :kanban)
      user = user_fixture()

      assert {:ok, %Ticket{} = ticket} =
               Support.create_ticket_in_space(
                 space.id,
                 %{subject: "In space", requester_id: user.id},
                 user.id
               )

      assert ticket.space_id == space.id
    end

    test "move_ticket_on_kanban_board/7 transitions status and persists rank ordering" do
      space = space_fixture(template: :kanban)
      user = user_fixture()

      assert {:ok, t1} =
               Support.create_ticket_in_space(
                 space.id,
                 %{subject: "A", requester_id: user.id},
                 user.id
               )

      assert {:ok, t2} =
               Support.create_ticket_in_space(
                 space.id,
                 %{subject: "B", requester_id: user.id},
                 user.id
               )

      assert {:ok, t3} =
               Support.create_ticket_in_space(
                 space.id,
                 %{subject: "C", requester_id: user.id},
                 user.id
               )

      # Move t2 from todo -> done, placing it first in done column
      assert {:ok, moved} =
               Support.move_ticket_on_kanban_board(
                 space.id,
                 t2.id,
                 "todo",
                 "done",
                 ["#{t1.id}", "#{t3.id}"],
                 ["#{t2.id}"],
                 user.id
               )

      assert moved.status == :solved

      tickets = Support.list_tickets_by_space(space.id)

      # todo column ranks (t1 then t3)
      assert Enum.find(tickets, &(&1.id == t1.id)).rank == 1
      assert Enum.find(tickets, &(&1.id == t3.id)).rank == 2

      # done column rank
      assert Enum.find(tickets, &(&1.id == t2.id)).rank == 1
    end

    test "fetch_ticket!/1 returns ticket with preloaded assocs" do
      ticket = ticket_fixture()
      fetched_ticket = Support.fetch_ticket!(ticket.id)

      assert fetched_ticket.id == ticket.id
      assert Ecto.assoc_loaded?(fetched_ticket.requester)
      assert Ecto.assoc_loaded?(fetched_ticket.comments)
    end

    test "edit_ticket_details/2 updates simple fields" do
      ticket = ticket_fixture()
      update_attrs = %{subject: "New Subject"}

      assert {:ok, updated_ticket} = Support.edit_ticket_details(ticket, update_attrs)
      assert updated_ticket.subject == "New Subject"
    end

    test "edit_ticket_details/2 ignores status changes" do
      ticket = ticket_fixture(status: :open)
      # Try to force status change via edit
      update_attrs = %{status: :closed, subject: "Changed"}

      assert {:ok, updated_ticket} = Support.edit_ticket_details(ticket, update_attrs)
      assert updated_ticket.subject == "Changed"
      assert updated_ticket.status == :open
    end

    test "browse_tickets/1 with filters" do
      user1 = user_fixture()
      user2 = user_fixture()

      t1 = ticket_fixture(requester_id: user1.id, status: :open, priority: :high)
      t2 = ticket_fixture(requester_id: user2.id, status: :solved, priority: :normal)

      # Filter by status
      assert [fetched_t1] = Support.browse_tickets(status: :open)
      assert fetched_t1.id == t1.id

      # Filter by requester
      assert [fetched_t2] = Support.browse_tickets(requester_id: user2.id)
      assert fetched_t2.id == t2.id

      # Filter by priority
      assert [fetched_t1_high] = Support.browse_tickets(priority: :high)
      assert fetched_t1_high.id == t1.id
    end
  end

  describe "ticket lifecycle" do
    test "await_customer_reply/2 transitions open -> pending" do
      ticket = ticket_fixture(status: :open)
      user = user_fixture()

      assert {:ok, updated} = Support.await_customer_reply(ticket, user.id)
      assert updated.status == :pending
    end

    test "hold_ticket/3 transitions to on_hold" do
      ticket = ticket_fixture(status: :open)
      user = user_fixture()

      assert {:ok, updated} = Support.hold_ticket(ticket, user.id, "Waiting for vendor")
      assert updated.status == :on_hold
    end

    test "resume_ticket/2 transitions on_hold -> open" do
      ticket = ticket_fixture(status: :open)
      user = user_fixture()

      {:ok, on_hold} = Support.hold_ticket(ticket, user.id)
      assert {:ok, resumed} = Support.resume_ticket(on_hold, user.id)
      assert resumed.status == :open
    end

    test "resolve_issue/2 transitions to solved and sets solved_at" do
      ticket = ticket_fixture(status: :open)
      user = user_fixture()

      assert {:ok, solved} = Support.resolve_issue(ticket, user.id)
      assert solved.status == :solved
      assert solved.solved_at != nil
    end

    test "close_ticket/2 transitions solved -> closed" do
      ticket = ticket_fixture(status: :open)
      user = user_fixture()

      {:ok, solved} = Support.resolve_issue(ticket, user.id)
      assert {:ok, closed} = Support.close_ticket(solved, user.id)
      assert closed.status == :closed
      assert closed.closed_at != nil
    end

    test "close_ticket/2 fails if not solved" do
      ticket = ticket_fixture(status: :open)
      user = user_fixture()

      assert {:error, :must_be_solved_first} = Support.close_ticket(ticket, user.id)
    end
  end

  describe "comments" do
    test "add_comment/3 adds a comment and logs activity" do
      ticket = ticket_fixture()
      user = user_fixture()

      assert {:ok, comment} = Support.add_comment(ticket.id, user.id, %{body: "Hello"})
      assert comment.body == "Hello"
      assert comment.ticket_id == ticket.id
      assert comment.author_id == user.id

      # Check activity log
      activities = Support.list_activities(ticket.id)
      assert Enum.any?(activities, fn a -> a.action == :commented end)
    end

    test "list_comments/2 returns comments" do
      ticket = ticket_fixture()
      comment1 = comment_fixture(ticket_id: ticket.id, body: "First")
      # Ensure timestamp difference
      Process.sleep(10)
      comment2 = comment_fixture(ticket_id: ticket.id, body: "Second")

      comments = Support.list_comments(ticket.id)
      assert length(comments) == 2
      assert Enum.at(comments, 0).id == comment1.id
      assert Enum.at(comments, 1).id == comment2.id
    end
  end
end
