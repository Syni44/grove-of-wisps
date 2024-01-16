defmodule GroveOfWispsWeb.PageController do
  use GroveOfWispsWeb, :controller

  def home(conn, _params) do
    n = :rand.uniform(5)
    IO.puts(n)

    conn
    |> assign(:paragraphs, n)
    |> render(:home, layout: false)
  end
end
