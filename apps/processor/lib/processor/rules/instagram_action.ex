defmodule Processor.Rules.InstagramAction do
  @moduledoc """
  Rules for instagram actions.
  """

  def is_reviewed(review_status, reward_maps) do
    id = {"is_reviewed", review_status}

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
end
