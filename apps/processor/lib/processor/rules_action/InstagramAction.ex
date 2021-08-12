defmodule Processor.RulesAction.InstagramAction do
  @moduledoc """
  This is an `Action` module.
  This module receives action info and rules and this information generates an action structure.
  """

  alias Processor.Rating

  def instagram_action(info, rules) do
    dharma = Rating.InstagramAction.rate(info, rules)

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
end
