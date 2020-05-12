defmodule ForecastSubscriber.Application do
  use Application

   def start(_type, _args) do

    port = 4051
    opts = [:binary, active: false]
    socket = case :gen_udp.open(port, opts) do
      {:ok, socket} -> socket
      {:error, _reason} ->
        Process.exit(self(), :normal)
    end

    children = [
      %{
        id: Fetcher,
        start: {Fetcher, :start_link, [socket]}
      },

      %{
        id: Aggregator,
        start: {Aggregator, :start_link, [socket]}
      }
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)

      receive do
      end
    end
  end
