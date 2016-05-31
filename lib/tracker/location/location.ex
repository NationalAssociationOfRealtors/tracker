defmodule Tracker.Location do
    use GenServer
    require Logger

    alias Tracker.Message
    alias Tracker.Location.Sensor.Camera
    alias Tracker.Location.Sensor.Placemeter, as: Stats

    def start_link(message = %Message{}) do
        GenServer.start_link(__MODULE__, message, name: message.id)
    end

    def add_event_handler(node, handler, parent) do
        GenServer.call(node, {:add_handler, handler, parent})
    end

    def remove_event_handler(node, handler) do
        GenServer.call(node, {:remove_handler, handler})
    end

    def init(message = %Message{}) do
        IO.inspect message
        url = message.data["url"]
        {:ok, events} = GenEvent.start_link([])
        {:ok, camera} = Camera.start_link(url, events)
        {:ok, pm} = Stats.start_link(events)
        Logger.info "Location: #{message.id} started"
        {:ok, %{events: events, id: message.id}}
    end

    def handle_call({:add_handler, handler, parent}, _from, state) do
        {:reply, GenEvent.add_mon_handler(state.events, handler, parent), state}
    end

    def handle_call({:remove_handler, handler}, _from, state) do
        {:reply, GenEvent.remove_handler(state.events, handler, []), state}
    end

end
