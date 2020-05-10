defmodule ForecastSubscriber.Application do
  use Application

   def start(_type, _args) do

    children = [
      %{
        id: Forecast_Subscriber,
        start: {Forecast_Subscriber, :start_link, [4050]}
      }
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)

      receive do
      end
    end
  end
