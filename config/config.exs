import Config

config :kids_prep,
  ecto_repos: [KidsPrep.Repo],
  generators: [timestamp_type: :utc_datetime],
  notion: [
    hub_page_id: "3bab677e-d9b4-817c-ab8c-f67b40ae961e",
    questions_database_id: "814ae504b1a4479a9bbf038801e703e7",
    daily_modules_database_id: "956aa51d67744967be5e6d0e43e2cbed",
    results_database_id: "54ec1e84f6af4dfeb19f334ddf45cc0d",
    weak_skills_database_id: "4371e03fafcc4f87bc49a432a4573817"
  ]

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
