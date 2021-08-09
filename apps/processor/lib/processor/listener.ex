defmodule Processor.Listener do
  use GenServer

  @moduledoc """
  Listen for changes on rules and issue a reload if necessary.
  """

  # Convenience function for starting the module.
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    {seq, _ids} = Database.fetch_changes()
    new_state = Map.put(state, :seq, seq)
    schedule_fetch()
    {:ok, new_state}
  end

  @impl true
  def handle_info(:fetch, state) do
    {last_seq, ids} = Database.fetch_changes(state.seq)
    new_state = Map.put(state, :seq, last_seq)

    # TODO: Find a better way of getting all children (probably through Supervisor.which_children)
    if any_rule?(ids) do
      GenServer.cast(Processor, :reload)
    end

    schedule_fetch()
    {:noreply, new_state}
  end

  defp any_rule?(ids) do
    list_of_mapped_ids =
      ids
      |> Enum.map(&%{id: &1})

    {:ok, resp} = Database.post_to_db("_bulk_get", %{docs: list_of_mapped_ids})

    resp.body["results"]
    |> Enum.map(&hd(&1["docs"])["ok"]["type"])
    |> Enum.any?(&(&1 == "action_rules"))
  end

  # Could this be improved?
  defp schedule_fetch() do
    Process.send_after(self(), :fetch, 1000)
  end
end
