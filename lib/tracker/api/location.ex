defmodule Tracker.API.Location do
    require Logger
    alias Tracker.Location

    @db Application.get_env(:tracker, :influx_db)
    @measurement_points Application.get_env(:tracker, :measurementpoints_dets)

    defmodule State do
        defstruct [:user, :mp]
    end

    def init({:tcp, :http}, req, opts) do
        {user_id, req} = :cowboy_req.qs_val("user_id", req)
        {:ok, mp} = :dets.open_file(:mp_dets, [type: :set])
        {:ok, req, %State{:user => user_id, :mp => mp}}
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
        |> Enum.reduce([], fn(series, acc) ->
            Logger.info state.mp
            Logger.info :dets.first(state.mp)
            id = get_in(series, [:tags, :id]) |> String.to_integer
            Logger.info id
            desc = :dets.lookup(state.mp, id)
            |> IO.inspect
            |> List.first
            |> elem(1)
            m = Map.merge(series, %{description: desc})
            [m | acc]
        end)
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

    def get_names(series) do

    end

    def terminate(_reason, req, state) do
        :dets.close(state.mp)
        :ok
    end

end
