defmodule SensorPublisher.Application do
  use Application

  def start(_type, _args) do
    children = [
      %{
        id: MySupervisor,
        start: {MySupervisor, :start_link, []}
      },

      {Registry, [keys: :unique, name: :workers_registry]},

      %{
        id: Request,
        start: {Request, :start_link, ["http://localhost:4000/sensors"]}
      },

      %{
        id: Feeder,
        start: {Feeder, :start_link, [10]},
      },

      %{
        id: Publisher,
        start: {Publisher, :start_link, [4042]}
      }
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)

    receive do
    end
  end
end

