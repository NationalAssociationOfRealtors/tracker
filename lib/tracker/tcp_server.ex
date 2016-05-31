defmodule Tracker.TCPServer do

    alias Tracker.API
    alias Tracker.Websocket

    @port Application.get_env(:tracker, :tcp_port)

    def start_link do
        dispatch = :cowboy_router.compile([
            { :_,
                [
                    {"/", :cowboy_static, {:priv_file, :tracker, "index.html"}},
                    {"/static/[...]", :cowboy_static, {:priv_dir,  :tracker, "static"}},
                    #{"/ws", API.Websocket, []},
                    {"/stream", API.MJPEGHandler, []},
                    #{"/sensors", API.Sensors, []},
            ]}
        ])
        {:ok, _} = :cowboy.start_http(:http,
            100,
            [{:port, @port}],
            [{:env, [{:dispatch, dispatch}]}]
        )
    end
end
