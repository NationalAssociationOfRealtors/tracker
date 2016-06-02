defmodule Tracker.Supervisor do
    use Supervisor
    require Logger

    alias Tracker.Message

    @name __MODULE__

    def start_link do
        Supervisor.start_link(@name, :ok, name: @name)
    end

    def init(:ok) do
        children = [
            Tracker.DB.InfluxDB.child_spec,
            worker(Tracker.TCPServer, []),
            supervisor(Tracker.LocationSupervisor, [])
        ]
        supervise(children, strategy: :one_for_one)
    end
end
