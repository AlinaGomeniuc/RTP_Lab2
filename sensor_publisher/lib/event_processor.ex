defmodule Event_Processor do
  use GenServer

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
      data = Poison.decode!(event.data)
      avg_sensor_data = Calculate.calculate_sensor_avg(data)
      Publisher.publish(Publisher, avg_sensor_data)

      {:noreply, event_processor_worker_state}
  end

  defp get_worker(name) do
    {:via, Registry, {:workers_registry, name}}
  end
end
