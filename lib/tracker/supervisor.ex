defmodule Tracker.Supervisor do
    use Supervisor
    require Logger

    @name __MODULE__
    @token Application.get_env(:placemeter, :auth_token)

    def start_link do
        Supervisor.start_link(__MODULE__, :ok, name: @name)
    end

    def init(:ok) do
        children = [
            worker(Placemeter, []),
            worker(Tracker.TCPServer, []),
            supervisor(Tracker.LocationSupervisor, [])
        ]
        Logger.info "Placemeter Auth Token: #{@token}"
        supervise(children, strategy: :one_for_one)
    end
end
