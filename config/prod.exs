import Config

config :kids_prep, KidsPrep.Repo,
  stacktrace: false,
  show_sensitive_data_on_connection_error: false

config :kids_prep, KidsPrepWeb.Endpoint, force_ssl: [rewrite_on: [:x_forwarded_proto]]
