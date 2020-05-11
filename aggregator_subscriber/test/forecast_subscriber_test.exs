defmodule ForecastSubscriberTest do
  use ExUnit.Case
  doctest ForecastSubscriber

  test "greets the world" do
    assert ForecastSubscriber.hello() == :world
  end
end
