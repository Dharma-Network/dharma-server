defmodule Processor.Rating.InstagramAction do
  @moduledoc """
  This module rates instagram actions.
  """

  def rate(info, rules) do
    {dharma, _rewards} =
      %{
        "number_of_stories" => info["post"]["stories"],
        "is_reviewed" => info["post"]["reviewed"]
      }
      |> Processor.Rules.evaluate_rules(rules, info["action_type"])

    dharma
  end
end
