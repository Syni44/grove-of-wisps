defmodule GroveOfWispsWeb.UsersSessionController do
  use GroveOfWispsWeb, :controller

  alias GroveOfWisps.Accounts
  alias GroveOfWispsWeb.UsersAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:users_return_to, ~p"/user/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"users" => users_params}, info) do
    %{"email" => email, "password" => password} = users_params

    if users = Accounts.get_users_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> UsersAuth.log_in_users(users, users_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/user/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UsersAuth.log_out_users()
  end
end
