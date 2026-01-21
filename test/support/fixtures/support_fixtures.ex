defmodule ExDesk.SupportFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ExDesk.Support` context.
  """

  alias ExDesk.Support

  def unique_group_name, do: "Group #{System.unique_integer([:positive])}"
  def unique_ticket_subject, do: "Ticket #{System.unique_integer([:positive])}"

  def group_fixture(attrs \\ %{}) do
    {:ok, group} =
      attrs
      |> Enum.into(%{
        name: unique_group_name(),
        description: "some description"
      })
      |> Support.create_group()

    group
  end

  def ticket_fixture(attrs \\ %{}) do
    attrs = Enum.into(attrs, %{})
    # Ensure we have a requester
    attrs =
      if Map.has_key?(attrs, :requester_id) do
        attrs
      else
        user = ExDesk.AccountsFixtures.user_fixture()
        Map.put(attrs, :requester_id, user.id)
      end

    {:ok, ticket} =
      attrs
      |> Enum.into(%{
        subject: unique_ticket_subject(),
        description: "some description",
        priority: :normal,
        status: :open,
        channel: :web
      })
      |> Support.create_ticket()

    ticket
  end

  def comment_fixture(attrs \\ %{}) do
    attrs = Enum.into(attrs, %{})
    # Ensure ticket and author
    {ticket_id, attrs} = Map.pop(attrs, :ticket_id)
    {author_id, attrs} = Map.pop(attrs, :author_id)

    ticket_id = ticket_id || ticket_fixture().id

    author_id =
      author_id ||
        (
          user = ExDesk.AccountsFixtures.user_fixture()
          user.id
        )

    {:ok, comment} =
      Support.add_comment(ticket_id, author_id, Enum.into(attrs, %{body: "some comment"}))

    comment
  end
end
