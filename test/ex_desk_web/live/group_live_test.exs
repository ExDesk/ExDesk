defmodule ExDeskWeb.GroupLiveTest do
  use ExDeskWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ExDesk.AccountsFixtures
  import ExDesk.SupportFixtures

  describe "Index" do
    test "agent lists groups", %{conn: conn} do
      agent = user_fixture(%{role: :agent})
      group = group_fixture(%{name: "Tier 1"})

      {:ok, _view, html} = live(log_in_user(conn, agent), ~p"/groups")

      assert html =~ "Groups"
      assert html =~ group.name
    end

    test "agent does not see create/edit/delete actions", %{conn: conn} do
      agent = user_fixture(%{role: :agent})
      group = group_fixture(%{name: "Ops"})

      {:ok, view, _html} = live(log_in_user(conn, agent), ~p"/groups")

      refute has_element?(view, "a", "New Group")
      refute has_element?(view, "#group-#{group.id} a", "Edit")
      refute has_element?(view, "#group-#{group.id} button", "Delete")
    end
  end

  describe "Create" do
    test "admin can create a group", %{conn: conn} do
      admin = user_fixture(%{role: :admin})
      conn = log_in_user(conn, admin)

      {:ok, index_live, _html} = live(conn, ~p"/groups")

      {:ok, form_live, _html} =
        index_live
        |> element("a", "New Group")
        |> render_click()
        |> follow_redirect(conn, ~p"/groups/new")

      assert has_element?(form_live, "#group-form")

      _html =
        form_live
        |> form("#group-form", %{
          "group" => %{
            "name" => "Escalations",
            "description" => "Tier 2 group"
          }
        })
        |> render_submit()

      assert_patch(form_live, ~p"/groups")
      assert render(form_live) =~ "Escalations"
    end

    test "shows validation errors", %{conn: conn} do
      admin = user_fixture(%{role: :admin})
      conn = log_in_user(conn, admin)

      {:ok, view, _html} = live(conn, ~p"/groups/new")

      html =
        view
        |> form("#group-form", %{"group" => %{"name" => "", "description" => ""}})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end
  end

  describe "Edit" do
    test "admin can edit a group", %{conn: conn} do
      admin = user_fixture(%{role: :admin})
      group = group_fixture(%{name: "Old"})
      conn = log_in_user(conn, admin)

      {:ok, index_live, _html} = live(conn, ~p"/groups")

      {:ok, edit_live, _html} =
        index_live
        |> element("#group-#{group.id} a", "Edit")
        |> render_click()
        |> follow_redirect(conn, ~p"/groups/#{group.id}/edit")

      _html =
        edit_live
        |> form("#group-form", %{"group" => %{"name" => "New name"}})
        |> render_submit()

      assert_patch(edit_live, ~p"/groups")
      assert render(edit_live) =~ "New name"
    end

    test "agent cannot access edit", %{conn: conn} do
      agent = user_fixture(%{role: :agent})
      group = group_fixture()

      {:error, redirect} = live(log_in_user(conn, agent), ~p"/groups/#{group.id}/edit")
      assert {:live_redirect, %{to: path}} = redirect
      assert path == ~p"/groups"
    end
  end

  describe "Delete" do
    test "admin can delete a group", %{conn: conn} do
      admin = user_fixture(%{role: :admin})
      group = group_fixture(%{name: "To Delete"})

      {:ok, view, _html} = live(log_in_user(conn, admin), ~p"/groups")

      assert has_element?(view, "#group-#{group.id}")

      view
      |> element("#group-#{group.id} button[phx-click=\"delete\"]")
      |> render_click()

      refute has_element?(view, "#group-#{group.id}")
    end
  end

  describe "Authorization" do
    test "user cannot access groups", %{conn: conn} do
      user = user_fixture(%{role: :user})
      {:error, redirect} = live(log_in_user(conn, user), ~p"/groups")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/dashboard"
      assert %{"error" => _msg} = flash
    end

    test "agent cannot access new", %{conn: conn} do
      agent = user_fixture(%{role: :agent})
      {:error, redirect} = live(log_in_user(conn, agent), ~p"/groups/new")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/groups"
      assert %{"error" => _msg} = flash
    end
  end
end
