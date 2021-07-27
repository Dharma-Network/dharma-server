defmodule ConnectorTest do
  use ExUnit.Case
  doctest Connector

  test "if connector and the connector task supervisor dies, it gets relaunched" do
    # Obtain the initial info about children
    info = Supervisor.which_children(Extractor.Supervisor)

    # Kill every single process
    Supervisor.which_children(Extractor.Supervisor)
    |> Enum.each(fn x -> Process.exit(elem(x, 1), :kill) end)

    # Wait a bit to let the restarts happen and get the new info about the children
    :timer.sleep(100)
    new_info = Supervisor.which_children(Extractor.Supervisor)

    # Get the sets with pids for each info list
    get_pids = fn l -> Enum.map(l, fn x -> elem(x, 1) end) end
    initial_pids = MapSet.new(get_pids.(info))
    final_pids = MapSet.new(get_pids.(new_info))

    assert length(info) == length(new_info) && MapSet.disjoint?(initial_pids, final_pids)
  end
end
