defmodule Tracker.API.MJPEGHandler do
    require Logger

    alias Tracker.Location
    alias Tracker.Event
    alias Tracker.Message
    @boundary "boundarydonotcross"

    def delimiter do
        "\r\n--#{@boundary}\r\n"
    end

    def image_headers(image) do
        size = byte_size(image)
        "Content-Type: image/jpeg\r\nContent-Length: #{size}\r\n\r\n"
    end

    defmodule Handler do

        defmodule State do
            defstruct [:parent]
        end

        def init(parent) do
            {:ok, %State{:parent => parent}}
        end

        def handle_event(event = %Event{:type => :clock}, state) do
            {:ok, state}
        end

        def handle_event(event = %Event{:type => :image}, state) do
            send(state.parent, event)
            {:ok, state}
        end

        def handle_event(event = %Event{}, state) do
            {:ok, state}
        end

    end

    def init({:tcp, :http}, req, opts) do
        {method, req} = :cowboy_req.method(req)
        {location_id, req} = :cowboy_req.qs_val("location_id", req)
        {user_id, req} = :cowboy_req.qs_val("user_id", req)
        Logger.info "Got: #{location_id}"
        location = String.to_atom(location_id)
        id = "#{user_id}:#{location}"
        Logger.info "Getting Stream for: #{id}"
        headers = [
            {"cache-control", "no-cache"},
            {"connection", "close"},
            {"content-type", "multipart/x-mixed-replace;boundary=#{@boundary}"},
            {"expires", "Mon, 3 Jan 2000 12:34:56 GMT"},
            {"pragma", "no-cache"},
        ]
        {:ok, req2} = :cowboy_req.chunked_reply(200, headers, req)
        stream(location, id)
        {:loop, req2, []}
    end

    def info(event = %Event{:type => :image}, req, state) do
        msg = image_headers(event.value)
            <> event.value
            <> delimiter
        :cowboy_req.chunk(msg, req)
        {:loop, req, state}
    end

    def info(_, req, state) do
        {:loop, req, state}
    end

    def stream(location, id) do
        Location.add_event_handler(location, {Handler, id}, self)
    end

    def terminate(reason, req, state) do
        :ok
    end

end
