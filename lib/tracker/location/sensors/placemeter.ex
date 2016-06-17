defmodule Tracker.Location.Sensor.Placemeter do
    use GenServer
    require Logger

    alias Tracker.Event

    @refresh 10000
    @measurement_points Application.get_env(:tracker, :measurementpoints_dets)

    defmodule State do
        defstruct [:events, :placemeter, :mp]
    end

    def start_link(token, events) do
        GenServer.start_link(__MODULE__, [token, events])
    end

    def init([token, events]) do
        Logger.info "Token: #{token}"
        {:ok, pm} = Placemeter.start_link(token)
        {:ok, mp} = :dets.open_file(:mp_dets, [file: @measurement_points, type: :set])
        Process.send_after(self, :stats, 1000)
        {:ok, %State{events: events, placemeter: pm, mp: mp}}
    end

    def handle_info(:stats, state) do
        case Placemeter.measurementpoints(state.placemeter, 60) do
            {:ok, res} ->
                res |> update_points(state.mp)
                GenEvent.notify(state.events, %Event{type: :stats, value: res})
            other -> Logger.info "#{inspect other}"
        end
        Process.send_after(self, :stats, @refresh)
        {:noreply, state}
    end

    def update_points(stats, mp) do
        stats |> Enum.map(fn(p) ->
            obj = {p.id, p.name} |> IO.inspect
            case :dets.insert(mp, obj) do
                :ok -> :blergh
                {:error, reason} -> Logger.info reason
            end
        end)
    end

    def terminate(reason, state) do
        Logger.info "Terminating, closing DETS"
        :dets.close(state.mp)
        :ok
    end

end
