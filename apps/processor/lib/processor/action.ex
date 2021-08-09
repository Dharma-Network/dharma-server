defmodule Processor.Action do
  def to_action(info, rules) do
    case info["action_type"] do
      "pull_request" -> pull_request_to_action(info, rules["pull_request"])
    end
  end

  defp pull_request_to_action(info, rules) do
    dharma = Processor.Rating.rate_pull_request(info, rules)

    %{
      "type" => "pull_request",
      "owner" => info["owner"],
      "repo" => info["repo"],
      "title" => info["pull"]["title"],
      "number_of_lines" => info["pull"]["additions"],
      "user" => info["pull"]["user"]["login"],
      "is_reviewed" => evaluate_reviews(info["reviews"]),
      "commits" => info["pull"]["commits"],
      "dharma" => dharma
    }
  end

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
