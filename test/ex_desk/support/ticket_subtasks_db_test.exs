defmodule ExDesk.Support.TicketSubtasksDbTest do
  use ExDesk.DataCase, async: true

  import ExDesk.AccountsFixtures

  alias ExDesk.Repo

  describe "tickets.parent_id" do
    test "deleting a parent ticket nilifies parent_id on child tickets" do
      requester = user_fixture()
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      {1, [%{id: parent_id}]} =
        Repo.insert_all(
          "tickets",
          [
            %{
              subject: "Parent",
              description: "",
              status: "open",
              priority: "normal",
              channel: "web",
              requester_id: requester.id,
              inserted_at: now,
              updated_at: now
            }
          ],
          returning: [:id]
        )

      {1, [%{id: child_id}]} =
        Repo.insert_all(
          "tickets",
          [
            %{
              subject: "Child",
              description: "",
              status: "open",
              priority: "normal",
              channel: "web",
              requester_id: requester.id,
              parent_id: parent_id,
              inserted_at: now,
              updated_at: now
            }
          ],
          returning: [:id]
        )

      assert {1, _} = Repo.delete_all(from(t in "tickets", where: t.id == ^parent_id))

      child =
        Repo.one(
          from(t in "tickets",
            where: t.id == ^child_id,
            select: %{id: t.id, parent_id: t.parent_id}
          )
        )

      assert child.id == child_id
      assert is_nil(child.parent_id)
    end
  end
end
