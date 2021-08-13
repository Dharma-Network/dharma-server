defmodule Processor.Rules.PullRequest do
  @moduledoc """
  Rules for pull requests.
  """

  def number_of_lines(additions, reward_maps) do
    {nol, val} =
      Map.to_list(reward_maps)
      |> Enum.map(fn {k, v} -> {String.to_integer(k), v} end)
      |> Enum.sort_by(fn {k, _v} -> k end, :desc)
      |> Enum.find({additions, 0}, &(additions >= elem(&1, 0)))

    {{"number_of_lines", nol}, val}
  end

  def is_reviewed(review_status, reward_maps) do
    id = {"is_reviewed", Atom.to_string(review_status)}

    case review_status do
      :positive -> {id, reward_maps["positive"]}
      :negative -> {id, reward_maps["negative"]}
      :unreviewed -> {id, reward_maps["unreviewed"]}
    end
  end

  def is_merged(merge_status, reward_maps) do
    id = {"is_merged", merge_status}

    case merge_status do
      true -> {id, reward_maps["merged"]}
      _ -> {id, reward_maps["not_merged"]}
    end
  end
end
