defmodule ExDeskWeb.UserLive.LoginTest do
  use ExDeskWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ExDesk.AccountsFixtures
  import Swoosh.TestAssertions

  describe "login page" do
    test "renders login page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/log-in")

      assert html =~ "Welcome back"
      assert html =~ "Contact your administrator"
      assert html =~ "Sign in"
    end
  end

  describe "user login - password" do
    test "redirects if user logs in with valid credentials", %{conn: conn} do
      user = user_fixture() |> set_password()

      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      form =
        form(lv, "#login_form",
          user: %{email: user.email, password: valid_user_password(), remember_me: true}
        )

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/dashboard"
    end

    test "redirects to login page with a flash error if credentials are invalid", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      form =
        form(lv, "#login_form", user: %{email: "test@email.com", password: "123456"})

      render_submit(form)

      conn = follow_trigger_action(form, conn)
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/users/log-in"
    end
  end

  describe "re-authentication (sudo mode)" do
    setup %{conn: conn} do
      user = user_fixture()
      %{user: user, conn: log_in_user(conn, user)}
    end

    test "shows login page with email filled in", %{conn: conn, user: user} do
      {:ok, _lv, html} = live(conn, ~p"/users/log-in")

      assert html =~ "Please reauthenticate to continue"
      refute html =~ "Contact your administrator"
      assert html =~ "Sign in"

      assert html =~
               ~s(<input type="email" name="user[email]" id="login_form_email" value="#{user.email}")
    end
  end

  describe "user login - magic link" do
    test "sends magic link instructions if email is valid", %{conn: conn} do
      user = user_fixture()
      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      form =
        form(lv, "#login_form",
          user: %{email: user.email},
          action: "magic"
        )

      conn = submit_form(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "receive instructions"
      assert redirected_to(conn) == ~p"/users/log-in"
      assert_email_delivered_with(to: [user.email])
    end

    test "sends magic link (no-op) if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      form =
        form(lv, "#login_form",
          user: %{email: "unknown@example.com"},
          action: "magic"
        )

      conn = submit_form(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "receive instructions"
      assert redirected_to(conn) == ~p"/users/log-in"
      refute_email_delivered()
    end
  end
end
