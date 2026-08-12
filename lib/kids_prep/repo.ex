defmodule KidsPrep.Repo do
  use Ecto.Repo,
    otp_app: :kids_prep,
    adapter: Ecto.Adapters.SQLite3
end
