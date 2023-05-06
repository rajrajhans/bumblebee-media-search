defmodule PhoenixStarter.Repo do
  use Ecto.Repo,
    otp_app: :phoenix_starter,
    adapter: Ecto.Adapters.Postgres
end
