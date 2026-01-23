defmodule ExDesk.SupportSpacesTest do
  use ExDesk.DataCase, async: true

  alias ExDesk.Support
  alias ExDesk.Support.Space

  import ExDesk.SupportFixtures
  import ExDesk.AccountsFixtures

  describe "spaces" do
    @valid_attrs %{
      name: "IT Support",
      key: "IT",
      template: :service_desk,
      color: "#3B82F6",
      description: "IT helpdesk"
    }

    @invalid_attrs %{name: nil, key: nil, template: nil}

    test "list_spaces/0 returns all spaces" do
      space = space_fixture()
      assert Support.list_spaces() == [space]
    end

    test "get_space!/1 returns the space with given id" do
      space = space_fixture()
      assert Support.get_space!(space.id) == space
    end

    test "get_space_by_key/1 returns the space with given key" do
      space = space_fixture(key: "DEV")
      assert Support.get_space_by_key("DEV") == space
    end

    test "get_space_by_key/1 returns nil for non-existent key" do
      assert Support.get_space_by_key("NOPE") == nil
    end

    test "create_space/2 with valid data creates a space" do
      user = user_fixture()

      assert {:ok, %Space{} = space} = Support.create_space(@valid_attrs, user.id)
      assert space.name == "IT Support"
      assert space.key == "IT"
      assert space.template == :service_desk
      assert space.color == "#3B82F6"
      assert space.created_by_id == user.id
    end

    test "create_space/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Support.create_space(@invalid_attrs, user.id)
    end

    test "update_space/2 with valid data updates the space" do
      space = space_fixture()
      update_attrs = %{name: "Updated Name", color: "#10B981"}

      assert {:ok, %Space{} = updated} = Support.update_space(space, update_attrs)
      assert updated.name == "Updated Name"
      assert updated.color == "#10B981"
    end

    test "update_space/2 with invalid data returns error changeset" do
      space = space_fixture()
      assert {:error, %Ecto.Changeset{}} = Support.update_space(space, %{name: nil})
    end

    test "delete_space/1 deletes the space" do
      space = space_fixture()
      assert {:ok, %Space{}} = Support.delete_space(space)
      assert_raise Ecto.NoResultsError, fn -> Support.get_space!(space.id) end
    end

    test "change_space/1 returns a space changeset" do
      space = space_fixture()
      assert %Ecto.Changeset{} = Support.change_space(space)
    end

    test "count_tickets_by_space/1 returns 0 for space with no tickets" do
      space = space_fixture()
      assert Support.count_tickets_by_space(space) == 0
    end

    test "list_tickets_by_space/1 returns only tickets for the given space" do
      space1 = space_fixture()
      space2 = space_fixture()
      user = user_fixture()

      assert {:ok, t1} =
               Support.create_ticket_in_space(
                 space1.id,
                 %{subject: "One", requester_id: user.id},
                 user.id
               )

      assert {:ok, t2} =
               Support.create_ticket_in_space(
                 space1.id,
                 %{subject: "Two", requester_id: user.id},
                 user.id
               )

      assert {:ok, _t3} =
               Support.create_ticket_in_space(
                 space2.id,
                 %{subject: "Other", requester_id: user.id},
                 user.id
               )

      assert [fetched1, fetched2] = Support.list_tickets_by_space(space1.id)
      assert fetched1.id == t1.id
      assert fetched2.id == t2.id
    end
  end
end
