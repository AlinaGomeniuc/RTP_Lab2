defmodule MessageRegistry do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def add(registry_pid, packet) do
    GenServer.cast(registry_pid, {:add_message, packet})
  end

  def get(topic) do
    GenServer.call(__MODULE__, {:get_message, topic})
  end

  def init(_) do
    registry = Map.new()

    {:ok, registry}
  end

  def handle_cast({:add_message, packet}, registry_state) do
    {topic, message} = MessageParser.get_topic(packet)
    if Map.has_key?(registry_state, topic) do
      messages = Map.get(registry_state, topic)
      messages = messages ++ [message]
      registry_new_state = Map.put(registry_state, topic, messages)

      {:noreply, registry_new_state}
    else
      registry_new_state = Map.put(registry_state, topic, [message])

      {:noreply, registry_new_state}
    end
  end

  def handle_call({:get_message, topic}, _from, registry_state) do
    if registry_state == %{} do
      {:reply, [], registry_state}
    else
      messages = Map.get(registry_state, topic)
      new_registry_state = Map.put(registry_state, topic, [])

      {:reply, messages, new_registry_state}
    end
  end

end
