defmodule PrinterSubscriber.Application do
  use Application

   def start(_type, _args) do

    children = [
      %{
        id: Printer_Subscriber,
        start: {Printer_Subscriber, :start_link, [4051]}
      }
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)

      receive do
      end
    end
  end
