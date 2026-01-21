defmodule ExDesk.Support.SpaceTest do
  use ExDesk.DataCase, async: true

  alias ExDesk.Support.Space

  describe "changeset/2" do
    test "valid changeset with required fields" do
      attrs = %{
        name: "IT Support",
        key: "IT",
        template: :service_desk
      }

      changeset = Space.changeset(%Space{}, attrs)
      assert changeset.valid?
    end

    test "requires name" do
      changeset = Space.changeset(%Space{}, %{key: "IT", template: :kanban})
      refute changeset.valid?
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "requires key" do
      changeset = Space.changeset(%Space{}, %{name: "IT Support", template: :kanban})
      refute changeset.valid?
      assert %{key: ["can't be blank"]} = errors_on(changeset)
    end

    test "requires template" do
      changeset = Space.changeset(%Space{}, %{name: "IT Support", key: "IT"})
      refute changeset.valid?
      assert %{template: ["can't be blank"]} = errors_on(changeset)
    end

    test "key must be uppercase letters only" do
      changeset = Space.changeset(%Space{}, %{name: "IT", key: "it-support", template: :kanban})
      refute changeset.valid?
      assert %{key: ["must be uppercase letters only (e.g., IT, HR, FAC)"]} = errors_on(changeset)
    end

    test "key max length is 10 characters" do
      changeset = Space.changeset(%Space{}, %{name: "IT", key: "VERYLONGKEY", template: :kanban})
      refute changeset.valid?
      assert %{key: ["should be at most 10 character(s)"]} = errors_on(changeset)
    end

    test "template must be valid enum value" do
      changeset = Space.changeset(%Space{}, %{name: "IT", key: "IT", template: :invalid})
      refute changeset.valid?
    end

    test "accepts optional color field" do
      attrs = %{name: "IT Support", key: "IT", template: :kanban, color: "#3B82F6"}
      changeset = Space.changeset(%Space{}, attrs)
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :color) == "#3B82F6"
    end

    test "accepts optional description field" do
      attrs = %{name: "IT Support", key: "IT", template: :kanban, description: "IT helpdesk"}
      changeset = Space.changeset(%Space{}, attrs)
      assert changeset.valid?
    end

    test "accepts optional icon field" do
      attrs = %{name: "IT Support", key: "IT", template: :kanban, icon: "hero-server"}
      changeset = Space.changeset(%Space{}, attrs)
      assert changeset.valid?
    end
  end

  describe "templates" do
    test "kanban template is valid" do
      attrs = %{name: "Dev Board", key: "DEV", template: :kanban}
      changeset = Space.changeset(%Space{}, attrs)
      assert changeset.valid?
    end

    test "service_desk template is valid" do
      attrs = %{name: "IT Help", key: "IT", template: :service_desk}
      changeset = Space.changeset(%Space{}, attrs)
      assert changeset.valid?
    end

    test "project template is valid" do
      attrs = %{name: "Planning", key: "PLAN", template: :project}
      changeset = Space.changeset(%Space{}, attrs)
      assert changeset.valid?
    end
  end
end
