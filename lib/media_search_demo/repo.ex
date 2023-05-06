defmodule MediaSearchDemo.Repo do
  use Ecto.Repo,
    otp_app: :media_search_demo,
    adapter: Ecto.Adapters.Postgres
end
