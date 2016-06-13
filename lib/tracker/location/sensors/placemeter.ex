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
        Process.send_after(self, :stats, 1000)
        {:ok, %{events: events, pm: pm}}
    end

    def handle_info(:stats, state) do
        case Placemeter.measurementpoints(state.pm, 60) do
            {:ok, res} ->
                GenEvent.notify(state.events, %Event{type: :stats, value: res})
            other -> Logger.info "#{inspect other}"
        end
        Process.send_after(self, :stats, @refresh)
        {:noreply, state}
    end

end
