defmodule ConnectorTest do
  use ExUnit.Case
  doctest Connector

  # Auxiliar function that exits every child of the given module.
  # Returns info about how many childs and what they pids where at the beggining and the end for that module.
  defp perform_respawns(module) do
    # Obtain the initial info about children
    info = Supervisor.which_children(module)
    IO.inspect info

    # Kill every single process
    Supervisor.which_children(module)
    |> Enum.each(fn x -> Process.exit(elem(x, 1), :kill) end)

    # Wait a bit to let the restarts happen and get the new info about the children
    :timer.sleep(100)
    new_info = Supervisor.which_children(module)
    IO.inspect new_info

    # Get the sets with pids for each info list
    get_pids = fn l -> Enum.map(l, fn x -> elem(x,1) end) end
    initial_pids = MapSet.new(get_pids.(info))
    final_pids = MapSet.new(get_pids.(new_info))

    {length(info), length(new_info), initial_pids, final_pids}
  end

  test "if connector and the connector task supervisor dies, it gets relaunched" do
    {n_initial, n_final, initial_pids, final_pids} = perform_respawns(Connector.Supervisor)
    assert n_initial == n_final && MapSet.disjoint?(initial_pids, final_pids)
  end

  test "extractors get relaunched on exit" do
    {n_initial, n_final, initial_pids, final_pids} = perform_respawns(Connector.TaskSupervisor)
    assert n_initial == n_final && MapSet.disjoint?(initial_pids, final_pids)
  end
end
