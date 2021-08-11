defmodule Database do
  @moduledoc """
  Documentation for `Database`.
  """
  defdelegate get_github_sources(), to: Database.Operations
  defdelegate get_rules(), to: Database.Operations
  defdelegate fetch_changes(), to: Database.Operations
  defdelegate post_to_db(path \\ "", body), to: Database.Operations
  defdelegate validate_user?(user_nickname, proj_id), to: Database.Operations
end
