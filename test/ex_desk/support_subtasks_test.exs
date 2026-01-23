defmodule ExDesk.SupportSubtasksTest do
  use ExDesk.DataCase, async: true

  alias ExDesk.Repo
  alias ExDesk.Support
  alias ExDesk.Support.Ticket

  import ExDesk.AccountsFixtures
  import ExDesk.SupportFixtures

  describe "create_subtask/3" do
    test "creates a child ticket and inherits space/requester" do
      space = space_fixture(template: :kanban)
      requester = user_fixture()

      assert {:ok, %Ticket{} = parent} =
               Support.create_ticket_in_space(
                 space.id,
                 %{subject: "Parent", requester_id: requester.id},
                 requester.id
               )

      assert {:ok, %Ticket{} = child} =
               Support.create_subtask(parent, %{subject: "Child"}, requester.id)

      assert child.parent_id == parent.id
      assert child.space_id == parent.space_id
      assert child.requester_id == parent.requester_id
    end

    test "enforces a maximum depth" do
      requester = user_fixture()

      assert {:ok, %Ticket{} = t0} =
               Support.create_ticket(%{subject: "T0", requester_id: requester.id}, requester.id)

      assert {:ok, %Ticket{} = t1} = Support.create_subtask(t0, %{subject: "T1"}, requester.id)
      assert {:ok, %Ticket{} = t2} = Support.create_subtask(t1, %{subject: "T2"}, requester.id)
      assert {:ok, %Ticket{} = t3} = Support.create_subtask(t2, %{subject: "T3"}, requester.id)

      assert {:error, changeset} = Support.create_subtask(t3, %{subject: "T4"}, requester.id)

      assert Enum.any?(errors_on(changeset).parent_id, fn msg ->
               String.contains?(msg, "exceeds maximum depth")
             end)
    end

    test "rejects creation when the parent chain has a circular reference" do
      requester = user_fixture()

      assert {:ok, %Ticket{} = a} =
               Support.create_ticket(%{subject: "A", requester_id: requester.id}, requester.id)

      assert {:ok, %Ticket{} = b} =
               Support.create_ticket(%{subject: "B", requester_id: requester.id}, requester.id)

      {1, _} = Repo.update_all(from(t in Ticket, where: t.id == ^a.id), set: [parent_id: b.id])
      {1, _} = Repo.update_all(from(t in Ticket, where: t.id == ^b.id), set: [parent_id: a.id])

      a = Repo.get!(Ticket, a.id)

      assert {:error, changeset} = Support.create_subtask(a, %{subject: "C"}, requester.id)

      assert Enum.any?(errors_on(changeset).parent_id, fn msg ->
               String.contains?(msg, "circular")
             end)
    end
  end

  describe "list_subtasks/1" do
    test "returns all child tickets for a parent" do
      requester = user_fixture()

      assert {:ok, %Ticket{} = parent} =
               Support.create_ticket(%{subject: "Parent", requester_id: requester.id}, requester.id)

      assert {:ok, %Ticket{} = c1} = Support.create_subtask(parent, %{subject: "C1"}, requester.id)
      assert {:ok, %Ticket{} = c2} = Support.create_subtask(parent, %{subject: "C2"}, requester.id)

      subtasks = Support.list_subtasks(parent.id)
      ids = Enum.map(subtasks, & &1.id)

      assert c1.id in ids
      assert c2.id in ids
    end
  end
end
