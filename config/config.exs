use Mix.Config

config :tracker, tcp_port: 8080

config :tracker, Tracker.DB.InfluxDB,
    host: "influx"

config :tracker, locations: [:"430n"]

config :tracker, :"430n",
    auth_token: System.get_env("PLACEMETER_AUTH_TOKEN_430N"),
    camera_url: System.get_env("PLACEMETER_CAMERA_URL_430N")
