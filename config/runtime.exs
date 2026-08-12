import Config

notion_env = [
  hub_page_id: System.get_env("KIDS_PREP_NOTION_HUB_PAGE_ID"),
  questions_database_id: System.get_env("KIDS_PREP_NOTION_QUESTIONS_DATABASE_ID"),
  daily_modules_database_id: System.get_env("KIDS_PREP_NOTION_DAILY_MODULES_DATABASE_ID"),
  results_database_id: System.get_env("KIDS_PREP_NOTION_RESULTS_DATABASE_ID"),
  weak_skills_database_id: System.get_env("KIDS_PREP_NOTION_WEAK_SKILLS_DATABASE_ID")
]

configured_notion =
  :kids_prep
  |> Application.get_env(:notion, [])
  |> Keyword.merge(Enum.reject(notion_env, fn {_key, value} -> value in [nil, ""] end))

config :kids_prep, notion: configured_notion

if config_env() == :prod do
  phx_host = System.get_env("PHX_HOST") || "kids-prep.miak-it.com"
  port = String.to_integer(System.get_env("PORT") || "4000")
  database_path = System.get_env("DATABASE_PATH") || "/app/data/kids_prep_prod.db"

  config :kids_prep, KidsPrep.Repo,
    database: database_path,
    journal_mode: :wal,
    busy_timeout: 5_000,
    foreign_keys: :on,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5")

  config :kids_prep, KidsPrepWeb.Endpoint,
    server: true,
    url: [host: phx_host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0}, port: port],
    check_origin: ["//#{phx_host}", "//www.#{phx_host}"],
    secret_key_base: System.fetch_env!("SECRET_KEY_BASE")
end
