defmodule Feeder do
  use GenServer

  def start_link(worker_count) do
    GenServer.start_link(__MODULE__, worker_count, name: __MODULE__)
  end

  def send_event(feeder_pid, event) do
    GenServer.cast(feeder_pid, {:send_event, event})
  end

  @impl true
  def init(worker_count) do
    workers = 1..worker_count |>
    Enum.map(fn id ->
      worker = "Worker #{id}"
      MySupervisor.start_child(worker)
      worker
    end)|> List.to_tuple

    event_count = 0
    worker_id = 0
    Process.send_after(self(), :check_events, 500)

    {:ok, {workers, worker_id, event_count}}
  end

  @impl true
  def handle_cast({:send_event, event}, feeder_state) do
    workers = elem(feeder_state, 0)
    worker_id = generate_worker_id(feeder_state)
    elem(workers, worker_id-1) |> Event_Processor.process_event(event)

    event_count = elem(feeder_state, 2) + 1

    {:noreply, {workers, worker_id, event_count}}
  end

  @impl true
  def handle_info(:check_events, feeder_state) do
    workers = elem(feeder_state, 0)
    worker_id = elem(feeder_state, 1)
    event_count = elem(feeder_state, 2)
    total_workers = tuple_size(workers)
    required_worker_nr = get_required_nr_workers(event_count)

    workers = restart_workers(workers)

    workers = cond do
      required_worker_nr > total_workers ->
        add_worker(workers, required_worker_nr, total_workers)

      required_worker_nr < total_workers ->
        delete_worker(workers, required_worker_nr, total_workers)

      true -> workers
      end

      Process.send_after(self(), :check_events, 500)

      {:noreply, {workers, worker_id, 0}}
  end

  defp generate_worker_id(state)do
    worker_count = elem(state, 1)
    worker_count = if worker_count < tuple_size(elem(state, 0)) do worker_count + 1  else  1 end
    worker_count
  end

  defp get_required_nr_workers(event_counter) do
    cond do
      event_counter < 10 -> 2
      event_counter > 10 && event_counter <= 30 -> 6
      event_counter > 30 && event_counter <= 50 -> 10
      event_counter > 50 && event_counter <= 70 -> 14
      event_counter > 70 && event_counter <= 100 -> 18
      event_counter > 100 && event_counter <= 130 -> 22
      event_counter > 130 && event_counter <= 150 -> 26
      event_counter > 150 && event_counter <= 170 -> 30
      event_counter > 170 && event_counter <= 200 -> 34
      event_counter > 200 && event_counter <= 250 -> 38
      event_counter > 250 && event_counter <= 300 -> 42
      event_counter > 300 && event_counter <= 350 -> 46
      event_counter > 350 && event_counter <= 400 -> 50
      event_counter > 400 && event_counter <= 450 -> 54
      event_counter > 450 -> 70
      true -> 10
    end
  end

  defp add_worker(workers, required_worker_nr, workers_count) do
    list_workers = Tuple.to_list(workers)

    new_workers = workers_count+1 .. required_worker_nr |>
    Enum.map(fn id ->
      worker = "Worker #{id}"
      MySupervisor.start_child(worker)
      worker
    end)

    list_workers ++ new_workers |> List.to_tuple
  end

  defp delete_worker(workers, required_worker_nr, workers_count) do
    list_workers = Tuple.to_list(workers)

    required_worker_nr+1 .. workers_count |>
    Enum.map(fn id ->
      worker = "Worker #{id}"
      List.delete(list_workers, worker)
      worker_registry = Registry.lookup(:workers_registry, worker)
      if (length(worker_registry) > 0) do
        hd(worker_registry) |> elem(0) |>
        MySupervisor.delete_child
      end
    end)

    Enum.slice(list_workers, 0, required_worker_nr) |> List.to_tuple
  end

  defp restart_workers(workers) do
    list_workers = Tuple.to_list(workers)
    workers = Enum.map(list_workers, fn id ->
      worker = "#{id}"
       if MySupervisor.start_child(worker) |> elem(0) == :ok do
        # IO.inspect "restarted #{worker}"
      end
      worker
    end) |> List.to_tuple
    workers
  end
end
