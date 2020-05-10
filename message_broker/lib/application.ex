defmodule MessageBroker.Application do
  use Application

   def start(_type, _args) do

    children = [
      %{
        id: UDPServer,
        start: {UDPServer, :start_link, [6161]}
      },

      %{
        id: MessageRegistry,
        start: {MessageRegistry, :start_link, []}
      },

      %{
        id: SubscriberData,
        start: {SubscriberData, :start_link, []}
      }
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)

      receive do
      end
    end
  end
