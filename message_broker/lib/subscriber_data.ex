defmodule SubscriberData do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def subscribe(data, packet) do
    GenServer.cast(__MODULE__, {:subscribe, data, packet})
  end

  def unsubscribe(data, packet) do
    GenServer.cast(__MODULE__, {:unsubscribe, data, packet})
  end

  def broadcast_messages(socket) do
    GenServer.cast(__MODULE__, {:broadcast_messages, socket})
   end

  def init(_) do
    subscriber_registry = Map.new()

    {:ok, subscriber_registry}
  end

  def handle_cast({:subscribe, data, packet}, subscriber_registry_state) do
    subscriber = {elem(data, 0), elem(data, 1)}
    {topic, _message} = MessageParser.get_topic(packet)
    topics = get_topics(topic)

    subscriber_registry_new_state =  Enum.reduce(topics, subscriber_registry_state, fn topic, acc ->
      Logger.info("Successfull subscribtion to #{topic}")
      if Map.has_key?(subscriber_registry_state, topic) do
        subscribers = Map.get(subscriber_registry_state, topic)
        subscribers = subscribers ++ [subscriber]
        Map.put(acc, topic, subscribers)
      else
        Map.put(acc, topic, [subscriber])
      end
    end)

    {:noreply, subscriber_registry_new_state}
  end

  def handle_cast({:unsubscribe, data, packet}, subscriber_registry_state) do
    subscriber = {elem(data, 0), elem(data, 1)}
    {topic, _message} = MessageParser.get_topic(packet)
    topics = get_topics(topic)

    subscriber_registry_new_state =  Enum.reduce(topics, subscriber_registry_state, fn topic, acc ->
      if Map.has_key?(subscriber_registry_state, topic) do
        subscribers = Map.get(subscriber_registry_state, topic)
        if Enum.member?(subscribers, subscriber) do
          subscribers = List.delete(subscribers, subscriber)
          Map.put(acc, topic, subscribers)
          Logger.info("Succesfull unsubscribed from #{topic}")
        else
          Logger.info("Error! Not subscribed to topic #{topic}")
          subscriber_registry_state
        end
      else
        Logger.info("Error! Not such topic #{topic}")
        subscriber_registry_state
      end
    end)

      {:noreply, subscriber_registry_new_state}
  end

  def handle_cast({:broadcast_messages, socket}, subscriber_registry_state) do
    topics = Map.keys(subscriber_registry_state)
    Enum.each(topics, fn topic ->
      hosts = Map.get(subscriber_registry_state, topic)
      messages = MessageRegistry.get(topic)
      if messages != nil do
        Enum.each(messages, fn message ->
          message = Map.put(message, "topic", topic)
          encoded_message = Poison.encode!(message)
          Enum.each(hosts, fn host ->
            address = elem(host, 0)
            port = elem(host, 1)
            :gen_udp.send(socket, address, port, encoded_message)
          end)
        end)
      else
        Logger.info("Error! Not such topic #{topic}")
      end
    end)
    {:noreply, subscriber_registry_state}
  end

  defp get_topics(topic) do
    topics =
      if String.contains?(topic, "/") do
        String.split(topic, "/", trim: true)
      else
        [topic]
      end
      topics
  end

end
