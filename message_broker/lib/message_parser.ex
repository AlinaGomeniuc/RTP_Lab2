defmodule MessageParser do

  def get_topic(packet) do
    topic = packet["topic"]
    packet = Map.delete(packet, "topic")
    {topic, packet}
  end

  def get_type(packet) do
    type = packet["type"]
    packet = Map.delete(packet, "type")
    {type, packet}
  end

  def decode_packet(encoded_packet) do
    Poison.decode!(encoded_packet)
  end
end
