defmodule GroveOfWisps.Repo do
  use Ecto.Repo,
    otp_app: :grove_of_wisps,
    adapter: Ecto.Adapters.Postgres
end
