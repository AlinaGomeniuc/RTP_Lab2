defmodule MqttSubscriber.Application do
  use Application

   def start(_type, _args) do

    children = [
      %{
        id: Fetcher,
        start: {Fetcher, :start_link, [4053]}
      },

      %{
        id: MqttAdapter,
        start: {MqttAdapter, :start_link, [1883]}
      }
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)

      receive do
      end
    end
  end
