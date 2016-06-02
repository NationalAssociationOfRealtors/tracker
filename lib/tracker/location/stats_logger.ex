defmodule Tracker.Location.StatsLogger do
    use GenEvent
    require Logger

    alias Tracker.Event
    alias Tracker.DB.InfluxDB.DataPoint

    def handle_event(event = %Event{type: :stats}, state) do
        Enum.flat_map(event.value, fn(p) ->
            Enum.flat_map(p.classes, fn(class) ->
                Enum.map(p.data, fn(d) ->
                    d1 = Map.get(d[class], "direction_1")
                    d2 = Map.get(d[class], "direction_2")
                    dir1 = if d1, do: d1, else: 0
                    dir2 = if d2, do: d2, else: 0
                    type = if p.type, do: p.type, else: "turnstile"
                    %DataPoint{
                        timestamp: d["timestamp"],
                        tags: %{
                            id: p.id,
                            type: type,
                            sensor: 1,
                            class: class
                        },
                        fields: %{
                            direction_1: dir1,
                            direction_2: dir2,
                        }
                    }
                end)
            end)
        end)
        |> Tracker.DB.InfluxDB.write_points(:seconds)
        {:ok, state}
    end

    def handle_event(event = %Event{}, state) do
        {:ok, state}
    end

end
