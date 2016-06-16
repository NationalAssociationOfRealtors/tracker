defmodule Tracker.API.Location do
    require Logger
    alias Tracker.Location

    @db Application.get_env(:tracker, :influx_db)

    defmodule State do
        defstruct [:user]
    end

    def init({:tcp, :http}, req, opts) do
        {user_id, req} = :cowboy_req.qs_val("location_id", req)
        {:ok, req, %State{:user => user_id}}
    end

    def handle(req, state) do
        {location_id, req} = :cowboy_req.qs_val("location_id", req)
        Logger.info "Getting Historical Data for #{location_id}"
        res = "SELECT direction_1, direction_2 FROM \"#{@db}\".\"one_minute\".\"objects\" WHERE sensor='1' AND time > now() - 5h GROUP BY id"
        |> Tracker.DB.InfluxDB.query()
        {:ok, resp} = res
        |> Map.get(:results)
        |> IO.inspect
        |> List.first
        |> IO.inspect
        |> Map.get(:series, [])
        |> IO.inspect
        |> Poison.encode
        headers = [
            {"cache-control", "no-cache"},
            {"connection", "close"},
            {"content-type", "application/json"},
            {"expires", "Mon, 3 Jan 2000 12:34:56 GMT"},
            {"pragma", "no-cache"},
        ]
        {:ok, req2} = :cowboy_req.reply(200, headers, resp, req)
        {:ok, req2, state}
    end

    def terminate(_reason, req, state) do
        :ok
    end

end
