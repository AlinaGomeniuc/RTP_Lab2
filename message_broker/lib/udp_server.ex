defmodule UDPServer do
  require Logger
  def start_link(port) do
    opts = [:binary, active: false]
    server_pid = case :gen_udp.open(port, opts) do
      {:ok, socket} ->
        Broadcaster.start_link(socket)
        spawn_link(__MODULE__, :loop_acceptor, [socket])
      {:error, reason} ->
        Logger.info("Could not start udp server! Reason: #{reason}")
        Process.exit(self(), :normal)
    end
    {:ok, server_pid}
  end

  def loop_acceptor(socket) do
    case :gen_udp.recv(socket, 0) do
      {:ok, data} ->
        encoded_packet = elem(data, 2)
        packet = MessageParser.decode_packet(encoded_packet)
        {type, packet} = MessageParser.get_type(packet)

        IO.inspect(data)

        case type do
          "message" -> MessageRegistry.add(MessageRegistry, packet)
          "subscribe" -> SubscriberData.subscribe(SubscriberData, data, packet)
          "unsubscribe" -> SubscriberData.unsubscribe(SubscriberData, data, packet)
        end

    end
    loop_acceptor(socket)
  end
end
