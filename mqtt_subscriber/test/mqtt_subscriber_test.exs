defmodule MqttSubscriberTest do
  use ExUnit.Case
  doctest MqttSubscriber

  test "greets the world" do
    assert MqttSubscriber.hello() == :world
  end
end
