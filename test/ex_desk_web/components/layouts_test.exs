defmodule ExDeskWeb.Components.LayoutsTest do
  use ExDeskWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import Phoenix.Component
  alias ExDeskWeb.Layouts

  test "sidebar/1 renders avatar when user has avatar_url" do
    user = %ExDesk.Accounts.User{
      email: "jane@example.com",
      avatar_url: "https://example.com/avatar.png"
    }

    current_scope = %{user: user}
    assigns = %{current_scope: current_scope}

    html = rendered_to_string(~H"<Layouts.sidebar current_scope={@current_scope} />")

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

    html = rendered_to_string(~H"<Layouts.sidebar current_scope={@current_scope} />")

    refute html =~ "<img"
    assert html =~ "J"
  end

  test "sidebar/1 renders Tickets navigation link" do
    user = %ExDesk.Accounts.User{
      email: "agent@example.com",
      avatar_url: nil
    }

    current_scope = %{user: user}
    assigns = %{current_scope: current_scope}

    html = rendered_to_string(~H"<Layouts.sidebar current_scope={@current_scope} />")

    assert html =~ ~s(href="/tickets")
    assert html =~ "Tickets"
  end
end
