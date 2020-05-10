defmodule Pub2Test do
  use ExUnit.Case
  doctest Pub2

  test "greets the world" do
    assert Pub2.hello() == :world
  end
end
