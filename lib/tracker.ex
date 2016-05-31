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
        Tracker.Supervisor.start_link()
    end
end
