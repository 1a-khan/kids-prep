import Config

config :kids_prep,
  ecto_repos: [KidsPrep.Repo],
  generators: [timestamp_type: :utc_datetime],
  notion: []

config :kids_prep, KidsPrep.Repo,
  database: Path.expand("../kids_prep_dev.db", Path.dirname(__ENV__.file)),
  journal_mode: :wal,
  busy_timeout: 5_000,
  foreign_keys: :on,
  pool_size: 5,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true

config :kids_prep, KidsPrepWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: KidsPrepWeb.ErrorHTML, json: KidsPrepWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: KidsPrep.PubSub,
  live_view: [signing_salt: "kids-prep-salt"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
