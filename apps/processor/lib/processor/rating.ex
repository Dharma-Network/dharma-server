defmodule Processor.Rating do
  def rate_pull_request(info, rules) do
    {dharma, _rewards} =
      %{
        "number_of_lines" => info["pull"]["additions"],
        # ver se vale a pena passar non_merged PR do extractor para o processor
        "is_merged" => true,
        "is_reviewed" => rate_reviews(info["reviews"])
      }
      |> Processor.Rules.evaluate_rules(rules)

    dharma
  end

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
