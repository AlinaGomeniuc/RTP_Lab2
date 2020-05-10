defmodule Event_Processor do
  use GenServer
  import SweetXml

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(name) do
    GenServer.start_link(__MODULE__, [name], name: get_worker(name))
  end

  def process_event(worker, event) do
    GenServer.cast(get_worker(worker), {:process_event, event})
  end

  @impl true
  def init(name) do
    # IO.inspect "Starting #{name}"
    {:ok, name}
  end

  @impl true
  def terminate(_reason, _state) do
    DynamicSupervisor.terminate_child(MySupervisor, self())
  end

  @impl true
  def handle_cast({:process_event, event}, event_processor_worker_state) do
      data = Poison.decode!(event.data)["message"]
      avg_sensor_data = data |> get_xml_data |> create_map()
      Publisher.publish(Publisher, avg_sensor_data)

      {:noreply, event_processor_worker_state}
  end

  defp get_worker(name) do
    {:via, Registry, {:workers_registry, name}}
  end

  defp get_xml_data(xml) do
    humidity = xpath(xml, ~x"//humidity_percent/value"l, value: ~x"text()")
    temperature = xpath(xml, ~x"//temperature_celsius/value"l, value: ~x"text()")
    time = xpath(xml, ~x"//SensorReadings/@unix_timestamp_100us"l)
    {humidity, temperature, time}
  end

  defp get_avg(sensor) do
    first_element = List.first(sensor)[:value] |> charlist_to_float
    second_element = List.last(sensor)[:value] |> charlist_to_float
    (first_element + second_element)/2
  end

  defp charlist_to_float(value) do
    value |> to_string |> Float.parse |> elem(0)
  end

  defp create_map(sensors) do
    humidity = elem(sensors, 0) |> get_avg()
    temperature = elem(sensors, 1) |> get_avg()
    time = elem(sensors, 2) |> List.first |> charlist_to_float |> Kernel.trunc

    avg_weather_data = %{
      humidity: humidity,
      temperature: temperature,
      unix_timestamp_100us: time,
    }

    avg_weather_data
  end
end
