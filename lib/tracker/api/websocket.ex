defmodule Tracker.API.Websocket do
    @behaviour :cowboy_websocket_handler
    require Logger

    alias Tracker.Location
    alias Tracker.Event
    alias Tracker.Message

    @location "location"
    @stats "stats"

    defmodule State do
        defstruct [:user_id, locations: []]
    end

    defmodule Handler do

        defmodule State do
            defstruct [:parent, :id]
        end

        def init({parent, id}) do
            {:ok, %State{:parent => parent, :id => id}}
        end

        def handle_event(event = %Event{:type => :clock}, state) do
            {:ok, state}
        end

        def handle_event(event = %Event{:type => :image}, state) do
            {:ok, state}
        end

        def handle_event(event = %Event{}, state) do
            send(state.parent, %Event{event | :id => state.id})
            {:ok, state}
        end

    end

    def init({tcp, http}, _req, _opts) do
        {:upgrade, :protocol, :cowboy_websocket}
    end

    def websocket_init(_TransportName, req, _opts) do
        {user_id, req} = :cowboy_req.qs_val("user_id", req)
        Process.send_after(self, :heartbeat, 1000)
        {:ok, req, %State{user_id: user_id}}
    end

    def websocket_terminate(_reason, _req, state) do
        Logger.info "Terminating Websocket #{state.user_id}"
        Enum.each(state.locations, fn(id) ->
            h_id = "#{state.user_id}:#{id}"
            Location.remove_event_handler(id, {Handler, id})
        end)
        :ok
    end

    def websocket_handle({:text, data}, req, state) do
        message = data |> Poison.decode!(as: %Message{})
        message = %Message{message | :id => String.to_atom(message.id)}
        new_state = handle_message(message, state)
        resp = %Message{:type => :response, :data => :ok, :id => message.id} |> Poison.encode!
        {:reply, {:text, resp}, req, new_state}
    end

    def websocket_handle(_data, req, state) do
        {:ok, req, state}
    end

    def handle_message(message = %Message{:type => @location}, state) do
        case Process.whereis(message.id) do
            nil -> Tracker.LocationSupervisor.start_location(message)
            _ -> true
        end
        id = "#{state.user_id}:#{message.id}"
        Location.add_event_handler(message.id, {Handler, id}, {self, message.id})
        %State{state | :locations => Enum.into(state.locations, [message.id])}
    end

    def handle_message(message = %Message{}, state) do
        IO.inspect message
        Logger.info "Sending to: #{message.id}"
        send(message.id, message)
        state
    end

    def websocket_info(event = %Event{}, req, state) do
        {:reply, {:text, Poison.encode!(event)}, req, state}
    end

    def websocket_info(:heartbeat, req, state) do
        Process.send_after(self, :heartbeat, 1000)
        {:reply, {:text, Poison.encode!(%Event{type: :heartbeat})}, req, state}
    end

    def websocket_info(_info, req, state) do
        {:ok, req, state}
    end

end
