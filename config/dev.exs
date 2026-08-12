import Config

config :kids_prep, KidsPrepWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "NkYK8VPoiWFdKCxFV9AYm4o9GdS8oUnhNpAubErZmo23yZTtW4B9xigTTb3zFdkC",
  watchers: []

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
