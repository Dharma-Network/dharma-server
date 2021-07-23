defmodule ExtractorTest do
  use ExUnit.Case
  doctest Extractor

  test "Kill extractor and see if it comes back to life" do
    pid = :erlang.whereis(Extractor)
    Process.exit(pid, :exit)
    assert :erlang.whereis(Extractor) != :undefined
  end
end
