defmodule Pub1Test do
  use ExUnit.Case
  doctest Pub1

  test "greets the world" do
    assert Pub1.hello() == :world
  end
end
