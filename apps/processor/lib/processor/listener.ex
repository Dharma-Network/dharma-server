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
    schedule_fetch()
    {:ok, state}
  end

  @impl true
  def handle_info(:fetch, state) do
    if Database.fetch_changes() != [] do
      GenServer.cast(Processor, :reload)
    end

    schedule_fetch()
    {:noreply, state}
  end

  # Could this be improved?
  defp schedule_fetch() do
    Process.send_after(self(), :fetch, 1000)
  end
end
