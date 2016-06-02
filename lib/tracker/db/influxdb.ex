defmodule Tracker.DB.InfluxDB do
    use Instream.Connection, otp_app: :tracker
    require Logger

    @db Application.get_env(:tracker, :influx_db)

    defmodule DataPoint do
        defstruct(
            measurement: "objects",
            timestamp: nil,
            tags: %{
                id: nil,
                sensor: 1,
                type: nil,
                class: nil,
            },
            fields: %{
                direction_1: 0,
                direction_2: 0,
            }
        )
    end

    def create_database do
        "#{@db}"
            |> Instream.Admin.Database.create()
            |> execute()
    end

    def create_retention_policies do
        Instream.Admin.RetentionPolicy.create(
            "one_minute", @db, "30d", 1, true
        ) |> execute()

        Instream.Admin.RetentionPolicy.create(
            "ten_minute", @db, "180d", 1
        ) |> execute()

        Instream.Admin.RetentionPolicy.create(
            "thirty_minute", @db, "INF", 1
        ) |> execute()
    end

    def create_continuous_queries do
        """
        CREATE CONTINUOUS QUERY cq_10m ON #{@db}
        BEGIN SELECT sum(direction_1) AS direction_1, sum(direction_2) AS direction_2
        INTO "#{@db}"."ten_minute"."objects" FROM objects GROUP BY id, sensor, type, class, time(10m) END
        """ |> execute(method: :post)
        """
        CREATE CONTINUOUS QUERY cq_30m ON #{@db}
        BEGIN SELECT sum(direction_1) AS direction_1, sum(direction_2) AS direction_2
        INTO "#{@db}"."thirty_minute"."objects" FROM objects GROUP BY id, sensor, type, class, time(30m) END
        """ |> execute(method: :post)
    end

    def write_points(points, precision) do
        case %{database: @db, points: points} |> write([precision: precision]) do
            {status, headers, response} ->
                Logger.info "#{inspect status}"
                Logger.info "#{inspect headers}"
                Logger.info "#{inspect response}"
            anything ->
                Logger.info "#{inspect anything}"
        end
    end

end
