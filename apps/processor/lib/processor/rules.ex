defmodule Processor.Rules do
  @moduledoc """
  Encapsulate the logic of evaluating an action to dharma.
  In order to be as adaptable as possible, this module assumes that the info that is provided to the only public function comes in a pre-prepared structure that is explained in more detail in the documentation of `evaluate_rules`.
  """
  def number_of_lines(additions, reward_maps) do
    {nol, val} =
      Map.to_list(reward_maps)
      |> Enum.map(fn {k, v} -> {String.to_integer(k), v} end)
      |> Enum.sort_by(fn {k, _v} -> k end, :desc)
      |> Enum.find(&(additions >= elem(&1, 0)))

    {{"number_of_lines", nol}, val}
  end

  def is_reviewed(review_status, reward_maps) do
    case review_status do
      :positive -> {{"is_reviewed", "positive"}, reward_maps["positive"]}
      :negative -> {{"is_reviewed", "negative"}, reward_maps["negative"]}
      :unreviewed -> {{"is_reviewed", "unreviewed"}, reward_maps["unreviewed"]}
    end
  end

  def is_merged(merge_status, reward_maps) do
    id = {"is_merged", merge_status}

    case merge_status do
      true -> {id, reward_maps["merged"]}
      _ -> {id, reward_maps["not_merged"]}
    end
  end

  def is_reviewed_instagram(review_status, reward_maps) do
    id = {"is_reviewed_instagram", review_status}

    if review_status do
      {id, reward_maps["is_reviewed"]}
    else
      {id, reward_maps["not_reviewed"]}
    end
  end

  def number_of_stories(stories, reward_maps) do
    {nos, val} =
      Map.to_list(reward_maps)
      |> Enum.map(fn {k, v} -> {String.to_integer(k), v} end)
      |> Enum.sort_by(fn {k, _v} -> k end, :desc)
      |> Enum.find(&(stories >= elem(&1, 0)))

    {{"number_of_stories", nos}, val}
  end

  @doc """
  `info` is a map that has keys corresponding to the the private functions defined in this module. If `info` contains a key called `number_of_lines` then `evaluate_rules` will evaluate the corresponding value into a dharma reward.
  """
  def evaluate_rules(info, reward_maps) do
    info
    |> Enum.reduce_while({0, %{}}, fn {k, v}, {r, map} ->
      case apply(__MODULE__, String.to_atom(k), [v, reward_maps[k]]) do
        {id, "abort"} -> {:halt, {id, 0}}
        {id, reward} -> {:cont, {r + reward, Map.put(map, id, reward)}}
      end
    end)
  end
end
