defmodule Processor.RulesAction do
  @moduledoc """
  This is the `Action` module.
  This module receives action info and rules and this information generates an action structure.
  """

  @doc """
  Transforms information based on action types to an action structure.
  """
  def to_action(info, rules) do
    case info["action_type"] do
      "pull_request" -> pull_request_to_action(info, rules["pull_request"])
      "instagram_action" -> instagram_post_to_action(info, rules["instagram_action"])
    end
  end

  defp instagram_post_to_action(info, rules) do
    dharma = Processor.Rating.rate_instagram_post(info, rules)

    action = %{
      "type" => "action",
      "action_type" => info["action_type"],
      "title" => info["post"]["title"],
      "user" => info["post"]["user"],
      "stories" => info["post"]["stories"],
      "dharma" => dharma
    }

    {:ok, action}
  end

  # Serialize a pull_request action type to an action structure.
  defp pull_request_to_action(info, rules) do
    dharma = Processor.Rating.rate_pull_request(info, rules)

    action = %{
      "type" => "action",
      "action_type" => info["action_type"],
      "owner" => info["owner"],
      "repo" => info["repo"],
      "title" => info["pull"]["title"],
      "number_of_lines" => Enum.map(info["files"], & &1["additions"]) |> Enum.sum(),
      "user" => info["pull"]["user"]["login"],
      "is_reviewed" => evaluate_reviews(info["reviews"]),
      "commits" => length(info["commits"]),
      "dharma" => dharma,
      "closed_at" => info["pull"]["closed_at"],
      "created_at" => info["pull"]["created_at"]
    }

    if Database.validate_user?(action["user"], info["proj_id"]) do
      {:ok, action}
    else
      error_message = "User " <> action["user"] <> " doesn't belong to the project."
      {:abort, error_message}
    end
  end

  # Based on review value checks if it was reviewed or not.
  defp evaluate_reviews(reviews) do
    case reviews
         |> Enum.filter(&(&1 != "COMMENTED"))
         |> List.last() do
      "APPROVED" -> "Reviewed"
      "CHANGES_REQUESTED" -> "Changes Requested and not added"
      _ -> "Unreviewed"
    end
  end
end
