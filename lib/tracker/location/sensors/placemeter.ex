defmodule Tracker.Location.Sensor.Placemeter do
    use GenServer
    require Logger

    alias Tracker.Event

    @refresh 20000

    defmodule State do
        defstruct [:points, :events]
    end

    def start_link(events) do
        GenServer.start_link(__MODULE__, events)
    end

    def init(events) do
        Process.send_after(self, :stats, 0)
        {:ok, %{events: events}}
    end

    def handle_info(:stats, state) do
        {:ok, res} = Placemeter.measurementpoints(120) |> IO.inspect
        GenEvent.notify(state.events, %Event{type: :stats, value: res})
        Process.send_after(self, :stats, @refresh)
        {:noreply, state}
    end

end
