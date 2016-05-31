defmodule Tracker.Sensor.Camera do
    use GenServer
    require Logger
    alias Tracker.Event

    defmodule State do
        defstruct [:url, :events, image: "0", refresh: 1000]
    end

    def start_link(message) do
        {:ok, events} = GenEvent.start_link([])
        GenServer.start_link(__MODULE__, [message, events], name: message.id)
    end

    def add_event_handler(camera, handler, parent) do
        GenServer.call(camera, {:add_handler, handler, parent})
    end

    def get_image(url, state) do
        case async = HTTPoison.get(url) do
            {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
                body
            {:error, _other} ->
                Logger.info "Error getting image."
                state.image
        end
    end

    def handle_info(event = %HTTPoison.AsyncStatus{}, state) do
        IO.inspect event
        {:noreply, state}
    end

    def handle_info(event = %HTTPoison.AsyncHeaders{}, state) do
        IO.inspect event
        {:noreply, state}
    end

    def handle_info(event = %HTTPoison.AsyncChunk{}, state) do
        IO.inspect event
        {:noreply, state}
    end

    def handle_info(event = %HTTPoison.AsyncEnd{}, state) do
        IO.inspect event
        {:noreply, state}
    end

    def get_images(refresh) do
        Process.send_after(self, :image, refresh)
    end

    def init([message, events]) do
        state = %State{:url => message.id, :events => events}
        Logger.info("Camera Started: #{state.url}")
        get_images(state.refresh)
        {:ok, state}
    end

    def handle_info(:image, state) do
        new_state = %State{state | :image => get_image(state.url, state)}
        GenEvent.notify(state.events, %Event{:type => :image, :value => new_state.image})
        get_images(state.refresh)
        {:noreply, new_state}
    end

    def handle_call({:add_handler, handler, parent}, _from, state) do
        {:reply, GenEvent.add_mon_handler(state.events, handler, parent), state}
    end

end
