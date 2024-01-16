defmodule GroveOfWispsWeb.UsersSessionControllerTest do
  use GroveOfWispsWeb.ConnCase, async: true

  import GroveOfWisps.AccountsFixtures

  setup do
    %{users: users_fixture()}
  end

  describe "POST /user/log_in" do
    test "logs the users in", %{conn: conn, users: users} do
      conn =
        post(conn, ~p"/user/log_in", %{
          "users" => %{"email" => users.email, "password" => valid_users_password()}
        })

      assert get_session(conn, :users_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ users.email
      assert response =~ ~p"/user/settings"
      assert response =~ ~p"/user/log_out"
    end

    test "logs the users in with remember me", %{conn: conn, users: users} do
      conn =
        post(conn, ~p"/user/log_in", %{
          "users" => %{
            "email" => users.email,
            "password" => valid_users_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_grove_of_wisps_web_users_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the users in with return to", %{conn: conn, users: users} do
      conn =
        conn
        |> init_test_session(users_return_to: "/foo/bar")
        |> post(~p"/user/log_in", %{
          "users" => %{
            "email" => users.email,
            "password" => valid_users_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "login following registration", %{conn: conn, users: users} do
      conn =
        conn
        |> post(~p"/user/log_in", %{
          "_action" => "registered",
          "users" => %{
            "email" => users.email,
            "password" => valid_users_password()
          }
        })

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Account created successfully"
    end

    test "login following password update", %{conn: conn, users: users} do
      conn =
        conn
        |> post(~p"/user/log_in", %{
          "_action" => "password_updated",
          "users" => %{
            "email" => users.email,
            "password" => valid_users_password()
          }
        })

      assert redirected_to(conn) == ~p"/user/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Password updated successfully"
    end

    test "redirects to login page with invalid credentials", %{conn: conn} do
      conn =
        post(conn, ~p"/user/log_in", %{
          "users" => %{"email" => "invalid@email.com", "password" => "invalid_password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/user/log_in"
    end
  end

  describe "DELETE /user/log_out" do
    test "logs the users out", %{conn: conn, users: users} do
      conn = conn |> log_in_users(users) |> delete(~p"/user/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :users_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the users is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/user/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :users_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
