defmodule Tracker.Location.Sensor.Placemeter do
    use GenServer
    require Logger

    alias Tracker.Event

    @refresh 10000

    defmodule State do
        defstruct [:points, :events]
    end

    def start_link(token, events) do
        GenServer.start_link(__MODULE__, [token, events])
    end

    def init([token, events]) do
        Logger.info "Token: #{token}"
        {:ok, pm} = Placemeter.start_link(token)
        IO.inspect Placemeter
        Process.send_after(self, :stats, 1000)
        {:ok, %{events: events, pm: pm}}
    end

    def handle_info(:stats, state) do
        {:ok, res} = Placemeter.measurementpoints(state.pm, 60) |> IO.inspect
        GenEvent.notify(state.events, %Event{type: :stats, value: res})
        Process.send_after(self, :stats, @refresh)
        {:noreply, state}
    end

end
