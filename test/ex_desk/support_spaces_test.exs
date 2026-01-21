defmodule ExDesk.SupportSpacesTest do
  use ExDesk.DataCase, async: true

  alias ExDesk.Support
  alias ExDesk.Support.Space

  import ExDesk.SupportFixtures

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

    test "create_space/1 with valid data creates a space" do
      assert {:ok, %Space{} = space} = Support.create_space(@valid_attrs)
      assert space.name == "IT Support"
      assert space.key == "IT"
      assert space.template == :service_desk
      assert space.color == "#3B82F6"
    end

    test "create_space/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Support.create_space(@invalid_attrs)
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
  end
end
