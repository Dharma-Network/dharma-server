defmodule ProcessorTest do
  use ExUnit.Case
  doctest Processor

  test "Kill a processor to see if it comes back to life" do
    info = Supervisor.which_children(Processor.Supervisor)

    # Kill every single process
    Supervisor.which_children(Processor.Supervisor)
    |> Enum.each(fn x -> Process.exit(elem(x, 1), :kill) end)

    # Wait a bit to let the restarts happen and get the new info about the children
    :timer.sleep(100)
    new_info = Supervisor.which_children(Processor.Supervisor)

    # Get the sets with pids for each info list
    get_pids = fn l -> Enum.map(l, fn x -> elem(x, 1) end) end
    initial_pids = MapSet.new(get_pids.(info))
    final_pids = MapSet.new(get_pids.(new_info))

    # Check if there's the same amount of children with no matching pids
    assert length(info) == length(new_info) && MapSet.disjoint?(initial_pids, final_pids)
  end
end
