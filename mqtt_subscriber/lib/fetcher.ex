defmodule Fetcher do
  require Logger
  @spec start_link(char) :: {:ok, any}
  def start_link(port) do
    opts = [:binary, active: false]
    socket = case :gen_udp.open(port, opts) do
      {:ok, socket} -> socket
      {:error, _reason} ->
        Process.exit(self(), :normal)
    end
    pid = spawn_link(__MODULE__, :subscribe_data, [socket])

    {:ok, pid}
  end

  def subscribe_data (socket) do
    topic = UserInput.get_topic()

    packet = Map.new()
    packet = Map.put(packet, "type", "subscribe")
    packet = Map.put(packet, "topic", topic)
    encoded_package = Poison.encode!(packet)
    host = '127.0.0.1'
    case :gen_udp.send(socket, host, 6161, encoded_package) do
      :ok -> receive_data(socket)
    end
  end

  def receive_data (socket) do
    case :gen_udp.recv(socket, 0) do
      {:ok, data} ->
        packet = elem(data, 2)
        MqttAdapter.publish_message("mqtt", packet)

      {:error, reason} ->
        Logger.info("recv error in Fetcher! Reason #{reason}")
      end

      receive_data(socket)
    end
end
