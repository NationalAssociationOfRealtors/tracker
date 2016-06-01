defmodule Tracker do
    use Application
    require Logger

    defmodule Event do
        defstruct [:type, :value, :id]
    end

    defmodule Message do
        defstruct [:id, :type, :data, :ip, :port]
    end

    def start(_type, _args) do
        {:ok, pid} = Tracker.Supervisor.start_link()
        start_locations
        {:ok, pid}
    end

    def start_locations do
        Application.get_env(:tracker, :locations) |> Enum.each(fn(location) ->
            Tracker.LocationSupervisor.start_location(%Message{id: location})
        end)

    end
end
