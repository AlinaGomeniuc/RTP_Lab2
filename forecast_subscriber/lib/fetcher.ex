defmodule Fetcher do
  require Logger
  def start_link(socket) do
    pid = spawn_link(__MODULE__, :subscribe_data, [socket])

    {:ok, pid}
  end

  def subscribe_data (socket) do
    packet = Map.new()
    packet = Map.put(packet, "type", "subscribe")
    packet = Map.put(packet, "topic", "aggregator")
    encoded_package = Poison.encode!(packet)
    host = '127.0.0.1'
    case :gen_udp.send(socket, host, 6161, encoded_package) do
      :ok -> receive_data(socket)
    end
  end

  def receive_data (socket) do
    case :gen_udp.recv(socket, 0) do
      {:ok, data} ->
        packet = elem(data, 2) |> Poison.decode!()
        Forecast.generate_forecast(packet)

      {:error, reason} ->
        Logger.info("recv error in Fetcher get_message! Reason #{reason}")
      end

      receive_data(socket)
    end
end
