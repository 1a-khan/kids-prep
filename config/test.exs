import Config

config :kids_prep, KidsPrep.Repo,
  database: Path.expand("../kids_prep_test.db", Path.dirname(__ENV__.file)),
  journal_mode: :wal,
  busy_timeout: 5_000,
  foreign_keys: :on,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 5

config :kids_prep, KidsPrepWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base:
    "test-secret-key-base-for-kids-prep-liveview-that-is-long-enough-for-cookie-signing",
  server: false

config :logger, level: :warning
config :phoenix, :plug_init_mode, :runtime
