defmodule Database do
  @moduledoc """
  Documentation for `Database`.
  """
  defdelegate get_github_sources(), to: Database.Operations
  defdelegate get_rules(), to: Database.Operations
  defdelegate fetch_changes(since \\ ""), to: Database.Operations
  defdelegate post_to_db(path \\ "", body), to: Database.Operations
end
