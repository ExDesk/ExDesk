defmodule ExDeskWeb.UserLive.AccountTest do
  use ExDeskWeb.ConnCase

  import Phoenix.LiveViewTest
  import ExDesk.AccountsFixtures

  describe "Account Page" do
    test "renders markdown notes preview", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, lv, _html} = live(conn, ~p"/users/profile")

      lv
      |> form("#profile_form", user: %{notes: "# Hello Markdown\n- List Item"})
      |> render_change()

      assert has_element?(lv, "h1", "Hello Markdown")
      assert has_element?(lv, "li", "List Item")
    end

    test "renders save button with loading spinner capability", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, lv, _html} = live(conn, ~p"/users/profile")

      # We verify that the button has a spinner element that reacts to loading state.
      # We check for the presence of an element with 'loading-spinner' class inside the button
      assert has_element?(lv, "#profile_form button .loading-spinner")
    end

    test "shows unsaved changes warning when form is dirty", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, lv, _html} = live(conn, ~p"/users/profile")

      refute has_element?(lv, ".alert-warning", "You have unsaved changes")

      lv
      |> form("#profile_form", user: %{name: "New Name"})
      |> render_change()

      assert has_element?(lv, ".alert-warning", "You have unsaved changes")
    end

    test "preview avatar button shows image", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, lv, _html} = live(conn, ~p"/users/profile")

      url = "http://example.com/avatar.jpg"

      lv
      |> form("#profile_form", user: %{avatar_url: url})
      |> render_change()

      # Click preview button (targeting by text)
      lv
      |> element("button", "Preview")
      |> render_click()

      assert has_element?(lv, "img[src='#{url}']")
    end

    test "save button is disabled when form is pristine or invalid", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, lv, _html} = live(conn, ~p"/users/profile")

      # Initially disabled (pristine)
      assert has_element?(lv, "#profile_form button[disabled]")

      # Change to valid state
      lv
      |> form("#profile_form", user: %{name: "New Name"})
      |> render_change()

      refute has_element?(lv, "#profile_form button[disabled]")

      # Change to invalid state (empty name, assuming required)
      lv
      |> form("#profile_form", user: %{name: ""})
      |> render_change()

      assert has_element?(lv, "#profile_form button[disabled]")
    end
  end
end
