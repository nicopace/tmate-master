use Mix.Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
#
# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
config :tmate, TmateWeb.Endpoint,
  http: [port: System.get_env("MASTER_HTTP_PORT", "4000") |> String.to_integer(),
         compress: true, protocol_options: [
           proxy_header: System.get_env("USE_PROXY_PROTOCOL") == "1"]],
  url: System.get_env("MASTER_BASE_URL", "") |> URI.parse() |> Map.to_list(),
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  cache_static_manifest: "priv/static/cache_manifest.json"
# XXX If SSL options are needed. See tmate-websocket for example
config :tmate, TmateWeb.Endpoint, server: true

# Do not print debug messages in production
config :logger, level: :info

#database_url =
#  System.get_env("DATABASE_URL") ||
#    raise """
#    environment variable DATABASE_URL is missing.
#    For example: ecto://USER:PASS@HOST/DATABASE
#    """
#
#config :tmate, Tmate.Repo,
#  # ssl: true,
#  url: database_url,
#  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

pg = URI.parse(System.get_env("PG_URI", "pg://user:pass@host:5432/db"))
config :tmate, Tmate.Repo,
  adapter: Ecto.Adapters.Postgres,
  timeout: 60_000,
  username: pg.userinfo |> String.split(":") |> Enum.at(0),
  password: pg.userinfo |> String.split(":") |> Enum.at(1),
  database: pg.path |> String.split("/") |> Enum.at(1),
  port: pg.port,
  hostname: pg.host,
  pool_size: System.get_env("PG_POOLSIZE", "20") |> String.to_integer(),
  ssl: System.get_env("PG_SSL_CA_CERT") != nil,
  ssl_opts: [cacertfile: System.get_env("PG_SSL_CA_CERT")],
   # x4 all queue_target and queue_target settings,
   # in the hope to reduce the number of DBConnection Errors
  queue_target: 200,
  queue_interval: 4000


config :tmate, Tmate.Monitoring.Endpoint,
  port: System.get_env("MASTER_METRICS_PORT", "9100") |> String.to_integer()

config :tmate, :master,
  internal_api: [auth_token: System.get_env("INTERNAL_API_AUTH_TOKEN")]

config :tzdata, :autoupdate, :disabled

machine_index = System.get_env("HOSTNAME", "master-0")
                  |> String.split("-") |> Enum.at(-1) |> String.to_integer()

config :tmate, Tmate.MonitoringCollector,
  metrics_enabled: machine_index == 0

config :tmate, Tmate.Scheduler,
  enabled: machine_index == 0,
  jobs: [
    # every minute
    {"*/1 * * * *", {Tmate.SessionCleaner, :check_for_disconnected_sessions, []}},
    {"*/1 * * * *", {Tmate.SessionCleaner, :prune_sessions, []}},
  ]

config :tmate, Tmate.Mailer,
  adapter: Bamboo.MailgunAdapter,
  api_key: System.get_env("MAILGUN_API_KEY"),
  domain: "mail.tmate.io" # todo make it an env var
