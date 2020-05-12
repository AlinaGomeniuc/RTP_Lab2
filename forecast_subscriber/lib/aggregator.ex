defmodule Aggregator do
  use GenServer

  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket, name: __MODULE__)
  end

  def send_forecast(forecast_sensor_tuple) do
    GenServer.cast(__MODULE__, {:collect_forecast, forecast_sensor_tuple})
  end

  def init(socket) do
    Process.send_after(self(), :send_forecast, 1000)

    {:ok, {[], socket}}
  end

  def handle_cast({:collect_forecast, forecast_sensor_tuple}, aggregator_state) do
    socket = elem(aggregator_state, 1)
    forecast_map = elem(aggregator_state, 0)
    new_aggregator_state = forecast_map ++ [forecast_sensor_tuple]

    {:noreply, {new_aggregator_state, socket}}
  end

  def handle_info(:send_forecast, aggregator_state)do
    socket = elem(aggregator_state, 1)
    forecast_map = elem(aggregator_state, 0)


    if !Enum.empty?(forecast_map) do
      forecast =
      Calculate.sort_map(forecast_map) |>
      Calculate.get_first()

      sensors_data = Calculate.get_sensor_from_list(forecast_map, forecast)
      avg_data = calculate_avg_data(Tuple.to_list(sensors_data))

      send_to_broker(socket, forecast, avg_data)
    end

    Process.send_after(self(), :send_forecast, 1000)
    aggregator_new_state = Enum.drop(forecast_map, length(forecast_map))

    {:noreply, {aggregator_new_state, socket}}
  end

  defp calculate_avg_data(sensor_list_data) do
    pressure = Calculate.sum_data(sensor_list_data, "pressure") / length(sensor_list_data)
    humidity = Calculate.sum_data(sensor_list_data, "humidity") / length(sensor_list_data)
    light = Calculate.sum_data(sensor_list_data, "light") / length(sensor_list_data)
    wind_speed = Calculate.sum_data(sensor_list_data, "wind") / length(sensor_list_data)
    temperature = Calculate.sum_data(sensor_list_data, "temperature") / length(sensor_list_data)
    timestamp = Calculate.last_element(sensor_list_data, "unix_timestamp_100us")

    result = %{
      humidity: humidity,
      light: light,
      pressure: pressure,
      temperature: temperature,
      wind: wind_speed,
      timestamp: timestamp
    }
    result
  end

  defp send_to_broker(socket, forecast, data) do
    package = Map.put(data, :topic, "printer")|>
              Map.put(:type, "message")|>
              Map.put(:forecast, forecast)

    encoded_package = Poison.encode!(package)
    host = '127.0.0.1'
    case :gen_udp.send(socket, host, 6161, encoded_package) do
      :ok -> IO.inspect(encoded_package)
    end
  end


end
