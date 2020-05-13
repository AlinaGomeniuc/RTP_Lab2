defmodule MqttAdapter do
  use GenServer
  require Logger

  def start_link(port) do
    GenServer.start_link(__MODULE__, port, name: __MODULE__)
  end

  def publish_message(topic, message) do
    GenServer.cast(__MODULE__, {:publish_message, topic, message})
  end

  @impl true
  def init(port) do
    socket = case :gen_tcp.connect('localhost', port, [:binary, active: false]) do
      {:ok, socket} ->
        Logger.info("Connected to mosquitto")
        socket
      {:error, reason} ->
        Logger.info("Could not make a tcp connection!")
        Process.exit(self(), reason)
    end

    send_connect_message(socket)

    {:ok, socket}
  end

  @impl true
  def handle_cast({:publish_message, topic, message}, socket) do
    #compute flags
    <<flags::4>> = <<0::1, 0::integer-size(2), 0::1>>
    #topic length
    length_prefix = <<byte_size(topic)::big-integer-size(16)>>
    packet_type = 3
    data_publish = [<<packet_type::4, flags::4>>, variable_length_encode([[length_prefix, topic], message])]
    #send publish
    send_packet(socket, data_publish)

    {:noreply, socket}
  end

  defp send_connect_message(socket) do
    data_map = %{
      protocol: "MQTT",
      protocol_version: 0b00000100,
      user_name: nil,
      password: nil,
      clean_session: true,
      keep_alive: 60,
      client_id: "alina",
      will: nil
    }

    control_header = <<00010000>>

    protocol_type = [length_encode(data_map.protocol), data_map.protocol_version]

    flags = <<
      flag(data_map.user_name)::integer-size(1),
      flag(data_map.password)::integer-size(1),
      # will retain
      flag(0)::integer-size(1),
      # will qos
      0::integer-size(2),
      # will flag
      flag(0)::integer-size(1),
      flag(data_map.clean_session)::integer-size(1),
      # reserved bit
      0::1
    >>
    session_duration = <<data_map.keep_alive::big-integer-size(16)>>

    payload =
      [data_map.client_id, data_map.user_name, data_map.password] |>
      Enum.filter(&is_binary/1) |>
      Enum.map(&length_encode/1)

    connection_info = variable_length_encode([protocol_type, flags, session_duration, payload])

    data = [ control_header, connection_info ]

    send_packet(socket, data)
    recv_ack(socket)
  end

  defp send_packet(socket, packet) do
    case :gen_tcp.send(socket, packet) do
      :ok ->
        data = List.last(packet)
        message = List.last(data)
        IO.inspect(message)
      {:error, reason} -> Logger.info("Could not send packet! Reason: #{reason}")
    end
  end

  defp recv_ack(socket) do
    packet = case :gen_tcp.recv(socket, 0) do
      {:ok, packet} -> packet
      {:error, reason} ->
        Logger.info("Recv error! Reason: #{reason}")
    end

    <<_,_,_,return_code>> = packet

    if return_code == 0 do
      Logger.info("Acknowledge return code: #{return_code}")
    else
      Logger.error("Acknowledge error. Return code #{return_code}")
    end
  end

  defp variable_length_encode(data) when is_list(data) do
    length_prefix = data |> IO.iodata_length() |> remaining_length()
    length_prefix ++ data
  end

  @highbit 0b10000000
  defp remaining_length(n) when n < @highbit, do: [<<0::1, n::7>>]

  defp remaining_length(n) do
    [<<1::1, rem(n, @highbit)::7>>] ++ remaining_length(div(n, @highbit))
  end

  defp length_encode(data) do
    length_prefix = <<byte_size(data)::big-integer-size(16)>>
    [length_prefix, data]
  end

  defp flag(f) when f in [0, nil, false], do: 0

  defp flag(_), do: 1
end
