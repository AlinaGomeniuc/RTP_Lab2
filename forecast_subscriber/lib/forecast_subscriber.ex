defmodule Forecast_Subscriber do
  require Logger
  def start_link(port) do
    opts = [:binary, active: false]
    socket = case :gen_udp.open(port, opts) do
      {:ok, socket} -> spawn_link(__MODULE__, :subscribe_data, [socket])
      {:error, _reason} ->
        Process.exit(self(), :normal)
    end

    {:ok, socket}
  end

  def subscribe_data (socket) do
    packet = Map.new()
    packet = Map.put(packet, "type", "subscribe")
    packet = Map.put(packet, "topic", "iot/sensors")
    encoded_package = Poison.encode!(packet)
    host = '127.0.0.1'
    case :gen_udp.send(socket, host, 6161, encoded_package) do
      :ok -> IO.inspect(encoded_package)
      receive_data(socket)
    end
  end

  def receive_data (socket) do
    case :gen_udp.recv(socket, 0) do
      {:ok, data} ->
        encoded_packet = elem(data, 2)
        IO.inspect(encoded_packet)

      {:error, reason} ->
        Logger.info("recv error in Fetcher get_message! Reason #{reason}")
      end

      receive_data(socket)
    end

end
