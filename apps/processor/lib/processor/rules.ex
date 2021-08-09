defmodule Processor.Rules do
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
    case merge_status do
      true -> {{"is_merged", true}, reward_maps["merged"]}
      _ -> {{"is_merged", false}, String.to_atom(reward_maps["not_merged"])}
    end
  end

  def evaluate_rules(info, reward_maps) do
    info
    |> Enum.reduce_while({0, %{}}, fn {k, v}, {r, map} ->
      case apply(__MODULE__, String.to_atom(k), [v, reward_maps[k]]) do
        {id, :abort} -> {:halt, {id, 0}}
        {id, reward} -> {:cont, {r + reward, Map.put(map, id, reward)}}
      end
    end)
  end
end
