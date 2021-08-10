defmodule Processor.Listener do
  use GenServer

  @moduledoc """
  Listen for changes on rules and issue a reload if necessary.
  """
  # Possible race condition: if the listener/task somehow get killed
  # and there's a change in the rules, there is a very tiny small chance
  # that the listener wont listen to the last changes.

  # Convenience function for starting the module.
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, [{:name, __MODULE__}])
  end

  @impl true
  def init(state) do
    Task.async(fn -> wait_for_changes() end)
    {:ok, state}
  end

  @impl true
  def handle_cast(:reload, state) do
    GenServer.cast(Processor, :reload)
    {:noreply, state}
  end

  @impl true
  def handle_info(:reload, state) do
    GenServer.cast(Processor, :reload)
    {:noreply, state}
  end

  defp wait_for_changes do
    if Database.fetch_changes() != [] do
      GenServer.cast(__MODULE__, :reload)
    end

    wait_for_changes()
  end
end
