defmodule Publisher do
  use GenServer

  def start_link(port) do
    GenServer.start_link(__MODULE__, port, name: __MODULE__)
  end

  def publish(publisher_pid, event) do
    GenServer.cast(publisher_pid, {:publish_message, event})
  end

  @impl true
  def init(port) do
    opts = [:binary, active: false]
    socket = case :gen_udp.open(port, opts) do
      {:ok, socket} -> socket
      {:error, _reason} ->
        Process.exit(self(), :normal)
    end

    {:ok, socket}
  end

  @impl true
  def handle_cast({:publish_message, event}, socket) do
    package = Map.put(event, "topic", "sensors")
    package = Map.put(package, "type", "message")
    encoded_package = Poison.encode!(package)
    host = '127.0.0.1'
    case :gen_udp.send(socket, host, 6161, encoded_package) do
      :ok -> IO.inspect(encoded_package)
    end

    {:noreply, socket}
  end
end

