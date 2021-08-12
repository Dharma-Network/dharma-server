defmodule Processor.Rating.PullRequest do
  @moduledoc """
  This module rates pull request actions.
  """

  @doc """
  Rates a pull request by extracting the relevant data from it and evaluating the latter.
  """
  def rate(info, rules) do
    {dharma, _rewards} =
      %{
        "number_of_lines" => info["pull"]["additions"],
        "is_merged" => true,
        "is_reviewed" => rate_reviews(info["reviews"])
      }
      |> Processor.Rules.evaluate_rules(rules, info["action_type"])

    dharma
  end

  # rates an review based on its status
  defp rate_reviews(reviews) do
    case reviews
         |> Enum.filter(&(&1 != "COMMENTED"))
         |> List.last() do
      "APPROVED" -> :positive
      "CHANGES_REQUESTED" -> :negative
      _ -> :unreviewed
    end
  end
end
