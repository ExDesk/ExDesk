defmodule ExDesk.Support.TicketSchemaSubtasksTest do
  use ExDesk.DataCase, async: true

  import ExDesk.AccountsFixtures

  alias ExDesk.Support.Ticket

  describe "subtask relationships" do
    test "ticket schema defines parent/children associations" do
      assert Ticket.__schema__(:association, :parent)
      assert Ticket.__schema__(:association, :children)
    end
  end

  describe "subtask validations" do
    test "cannot set a ticket as its own parent" do
      requester = user_fixture()
      ticket = %Ticket{id: 123, subject: "A", requester_id: requester.id}

      changeset =
        ticket
        |> Ticket.update_changeset(%{subject: "A"})
        |> Ticket.set_parent(123)

      assert "cannot reference itself" in errors_on(changeset).parent_id
    end
  end
end
