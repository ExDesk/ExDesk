defmodule ExDeskWeb.Components.LayoutsTest do
  use ExDeskWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import Phoenix.Component
  import ExDeskWeb.Sidebar

  test "sidebar/1 renders avatar when user has avatar_url" do
    user = %ExDesk.Accounts.User{
      email: "jane@example.com",
      avatar_url: "https://example.com/avatar.png"
    }

    current_scope = %{user: user}
    assigns = %{current_scope: current_scope}

    html = rendered_to_string(~H"<.sidebar current_scope={@current_scope} />")

    assert html =~ ~s(<img src="https://example.com/avatar.png")
    refute html =~ "JE"
  end

  test "sidebar/1 renders initials when user has no avatar_url" do
    user = %ExDesk.Accounts.User{
      email: "jane@example.com",
      avatar_url: nil
    }

    current_scope = %{user: user}
    assigns = %{current_scope: current_scope}

    html = rendered_to_string(~H"<.sidebar current_scope={@current_scope} />")

    refute html =~ "<img"
    assert html =~ "J"
  end

  test "sidebar/1 renders Spaces section header" do
    user = %ExDesk.Accounts.User{
      email: "agent@example.com",
      avatar_url: nil
    }

    current_scope = %{user: user}
    assigns = %{current_scope: current_scope, spaces: []}

    html =
      rendered_to_string(~H"<.sidebar current_scope={@current_scope} spaces={@spaces} />")

    # Should have SPACES section header
    assert html =~ "Spaces"
    # Should have Create Space link
    assert html =~ "Create Space"
    assert html =~ ~s(href="/spaces/new")
  end

  test "sidebar/1 renders space items with colored icons" do
    user = %ExDesk.Accounts.User{
      email: "agent@example.com",
      avatar_url: nil
    }

    spaces = [
      %ExDesk.Support.Space{
        id: 1,
        name: "IT Support",
        key: "IT",
        color: "#3B82F6",
        template: :service_desk
      }
    ]

    current_scope = %{user: user}
    assigns = %{current_scope: current_scope, spaces: spaces}

    html =
      rendered_to_string(~H"<.sidebar current_scope={@current_scope} spaces={@spaces} />")

    assert html =~ "IT Support"
    assert html =~ ~s(href="/spaces/IT")
    # Should have colored icon style
    assert html =~ "#3B82F6"
  end
end
