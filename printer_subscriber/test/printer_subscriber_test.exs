defmodule PrinterSubscriberTest do
  use ExUnit.Case
  doctest PrinterSubscriber

  test "greets the world" do
    assert PrinterSubscriber.hello() == :world
  end
end
