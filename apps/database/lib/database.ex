defmodule Database do
  @moduledoc """
  Documentation for `Database`.
  """
  defdelegate get_github_sources(), to: Database.Operations
  defdelegate get_rules(), to: Database.Operations
  defdelegate post(body), to: Database.Operations
end
