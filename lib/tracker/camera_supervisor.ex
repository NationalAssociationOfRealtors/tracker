defmodule Tracker.CameraSupervisor do
    use Supervisor
    require Logger
    @name __MODULE__

    def start_link do
        Supervisor.start_link(@name, :ok, name: @name)
    end

    def init(:ok) do
        children = [
            worker(Tracker.Sensor.Camera, [], restart: :transient)
        ]
        supervise(children, strategy: :simple_one_for_one)
    end

    def start_camera(message) do
        Logger.info "Starting Camera #{inspect message}"
        Supervisor.start_child(@name, [message])
    end
end
