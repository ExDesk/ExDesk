defmodule ExDesk.Support.TicketStateMachineIntegrationTest do
  use ExDesk.DataCase, async: false

  alias ExDesk.Support.{Ticket, TicketStateMachine}

  setup do
    Ecto.Adapters.SQL.Sandbox.mode(ExDesk.Repo, {:shared, self()})
    user = ExDesk.AccountsFixtures.user_fixture()
    {:ok, user: user}
  end

  test "transition/2 successfully updates ticket status and persists it", %{user: user} do
    attrs = %{
      subject: "Test Ticket",
      description: "Desc",
      status: :open,
      requester_id: user.id,
      priority: :normal,
      channel: :web
    }

    {:ok, ticket} =
      %Ticket{}
      |> Ticket.create_changeset(attrs)
      |> Repo.insert()

    assert ticket.status == :open

    # Transition
    assert {:ok, updated_ticket} = TicketStateMachine.transition(ticket, :pending)
    assert updated_ticket.status == :pending

    # Verify persistence
    persisted = Repo.get!(Ticket, ticket.id)
    assert persisted.status == :pending
  end

  test "transition/2 returns error on invalid transition", %{user: user} do
    attrs = %{
      subject: "Test Ticket",
      status: :open,
      requester_id: user.id
    }

    {:ok, ticket} =
      %Ticket{}
      |> Ticket.create_changeset(attrs)
      |> Repo.insert()

    # Invalid: open -> closed (direct)
    assert {:error, _reason} = TicketStateMachine.transition(ticket, :closed)
  end
end
