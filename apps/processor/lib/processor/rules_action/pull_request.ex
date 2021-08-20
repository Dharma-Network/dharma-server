defmodule Processor.RulesAction.PullRequest do
  @moduledoc """
  This is an `Action` module.
  This module receives action info and rules and this information generates an action structure.
  """

  alias Processor.Rating

  # Serialize a pull_request action type to an action structure.
  def pull_request(info, rules, users) do
    additions = Enum.map(info["files"], & &1["additions"]) |> Enum.sum()
    pull = Map.put(info["pull"], "additions", additions)

    info =
      info
      |> Map.put("reviews", Enum.map(info["reviews"], & &1["state"]))
      |> Map.put("pull", pull)

    dharma = Rating.PullRequest.rate(info, rules)

    user = info["pull"]["user"]["login"]

    action = %{
      "type" => "action",
      "action_type" => info["action_type"],
      "owner" => info["owner"],
      "repo" => info["repo"],
      "title" => info["pull"]["title"],
      "number_of_lines" => info["pull"]["additions"],
      "user" => user,
      "is_reviewed" => evaluate_reviews(info["reviews"]),
      "commits" => length(info["commits"]),
      "dharma" => dharma,
      "closed_at" => info["pull"]["closed_at"],
      "created_at" => info["pull"]["created_at"],
      "external_id" => info["pull"]["id"]
    }

    cond do
      Map.has_key?(users, user) and
          Enum.member?(users[user], info["proj_id"]) ->
        {:ok, action, users}

      Database.validate_user?(action["user"], info["proj_id"]) ->
        users = Map.put(users, user, [user | users[user]])
        {:ok, action, users}

      true ->
        error_message = "User " <> action["user"] <> " doesn't belong to the project."
        {:abort, error_message}
    end
  end

  # Based on review value checks if it was reviewed or not.
  defp evaluate_reviews(reviews) do
    reviews
    |> Enum.filter(&(&1 != "COMMENTED"))
    |> List.last()
    |> case do
      "APPROVED" -> "Reviewed"
      "CHANGES_REQUESTED" -> "Changes Requested and not added"
      _ -> "Unreviewed"
    end
  end
end
