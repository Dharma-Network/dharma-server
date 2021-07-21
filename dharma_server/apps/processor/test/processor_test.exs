defmodule ProcessorTest do
  use ExUnit.Case
  doctest Processor

  test "greets the world" do
    assert Processor.hello() == :world
  end
end
