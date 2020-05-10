defmodule Request do
 def start_link(url) do
    request_pid = spawn_link(__MODULE__, :getData, [])
    {:ok, eventsource_pid} = EventsourceEx.new(url, stream_to: request_pid)
    spawn(__MODULE__, :check_eventsource, [eventsource_pid, url, request_pid])

    {:ok, request_pid}
  end

  def getData() do
    receive do
        event ->
            Feeder.send_event(Feeder, event)
    end
    getData()
  end

  def check_eventsource(eventsource_pid, url, request_pid) do
    Process.monitor(eventsource_pid)

    {:ok, new_eventsource_pid} =
      receive do
      _msg ->
        EventsourceEx.new(url, stream_to: request_pid)
    end
    check_eventsource(new_eventsource_pid, url, request_pid)
  end
end
