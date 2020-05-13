defmodule TimestampStreamer do
  use GenServer

  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket, name: __MODULE__)
  end

  def add(packet) do
    GenServer.cast(__MODULE__, {:add_message, packet})
  end

  def init(socket) do
    registry = Map.new()
    Process.send_after(self(), :time_stream, 1000)

    {:ok, {registry, socket}}
  end

  def handle_cast({:add_message, packet}, streamer_state) do
    state = elem(streamer_state, 0)
    socket = elem(streamer_state, 1)

    topic = packet["topic"]
    message = Map.delete(packet, "topic")

    if Map.has_key?(state, topic) do
      messages = Map.get(state, topic)
      messages = messages ++ [message]
      new_state = Map.put(state, topic, messages)

      {:noreply, {new_state, socket}}
    else
      new_state = Map.put(state, topic, [message])

      {:noreply, {new_state, socket}}
    end
  end

  def handle_info(:time_stream, streamer_state) do
    state = elem(streamer_state, 0)
    socket = elem(streamer_state, 1)

    iot_messages = Map.get(state, "iot")
    sensors_messages = Map.get(state, "sensors")
    legacy_sensors_messages = Map.get(state, "legacy_sensors")

    streamed_message =
      if iot_messages != nil do
        Enum.map(iot_messages, fn iot_message ->
        iot_timestamp = iot_message["unix_timestamp_100us"]
        sensor_message = get_appropiate_sensor_data(sensors_messages, iot_timestamp)
        legacy_message = get_appropriate_legacy_sensor_data(legacy_sensors_messages, iot_timestamp)

        if (sensor_message != nil) && (legacy_message != nil) do
          %{
            pressure: iot_message["atmo_pressure"],
            wind: iot_message["wind_speed"],
            light: sensor_message["light"],
            humidity: legacy_message["humidity"],
            temperature: legacy_message["temperature"],
            unix_timestamp_100us: iot_message["unix_timestamp_100us"],
            topic: "aggregator",
            type: "message"
          }
        else
          nil
        end
      end)
    else
      nil
    end

    if streamed_message != nil do
      final_message_list = Enum.filter(streamed_message, fn message ->
        message != nil
      end)

      if !Enum.empty?(final_message_list) do
        publish_message(final_message_list, socket)
      end
    end


    Process.send_after(self(), :time_stream, 1000)
    {:noreply, {%{}, socket}}
  end

  def publish_message(final_message_list, socket)do
    Enum.each(final_message_list, fn message ->
      case :gen_udp.send(socket, '127.0.0.1', 6161, Poison.encode!(message)) do
        :ok -> IO.inspect(Poison.encode!(message))
      end
    end)
  end

  @spec get_appropiate_sensor_data(any, any) :: nil | %{optional(<<_::40>>) => float}
  def get_appropiate_sensor_data(sensor_data, timestamp) do
    sensor_avg = if sensor_data != nil do
      sensor_appropriate_list = Enum.filter(sensor_data, fn data ->
        sensor_timestamp = data["unix_timestamp_100us"]
        ((timestamp - sensor_timestamp) <= 100) &&
        ((timestamp - sensor_timestamp) >= -100)
      end)

      sensor_avg =
      if Enum.empty?(sensor_appropriate_list) do
        nil
      else
        get_avg_apropriate_sensor_data(sensor_appropriate_list)
      end
      sensor_avg
    else
      nil
    end
    sensor_avg
  end

  def get_appropriate_legacy_sensor_data(legacy_data, timestamp) do
    legacy_avg = if legacy_data != nil do
      legacy_sensors_appropriate_list = Enum.filter(legacy_data, fn data ->
        legeacy_sensors_timestamp = data["unix_timestamp_100us"]
        ((timestamp - legeacy_sensors_timestamp) <= 100) &&
        ((timestamp - legeacy_sensors_timestamp) >= -100)
      end)

      legacy_avg =
      if Enum.empty?(legacy_sensors_appropriate_list) do
        nil
      else
        get_avg_apropriate_legacy_data(legacy_sensors_appropriate_list)
      end
      legacy_avg
    else
      nil
    end
    legacy_avg
  end

  def get_avg_apropriate_sensor_data(sensor_data_list) do
    avg = sum_data(sensor_data_list, "light") / Enum.count(sensor_data_list)
    map = Map.put(%{}, "light", avg)
    map
  end

  def get_avg_apropriate_legacy_data(sensor_data_list) do
    hum_avg = sum_data(sensor_data_list, "humidity") / Enum.count(sensor_data_list)
    temp_avg = sum_data(sensor_data_list, "temperature") / Enum.count(sensor_data_list)
    map = Map.put(%{}, "humidity", hum_avg)
    map = Map.put(map, "temperature", temp_avg)
    map
  end

  @spec sum_data(any, any) :: number
  def sum_data(list, key)do
    Enum.map(list, fn (x) -> x[key] end)|>
    Enum.sum
  end
end
