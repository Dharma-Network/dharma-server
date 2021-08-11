defmodule RulesActionTest do
  use ExUnit.Case
  require Logger
  doctest Processor.RulesAction

  test "Examplify processing an instagram action" do
    info = %{
      "action_type" => "instagram_action",
      "post" => %{
        "reviewed" => true,
        "stories" => 2,
        "title" => "Dharma Team Presentation",
        "user" => "user"
      }
    }

    rules = %{
      "instagram_action" => %{
        "is_reviewed_instagram" => %{"is_reviewed" => 20, "not_reviewed" => 0},
        "number_of_stories" => %{"1" => 50, "2" => 100, "4" => 200}
      }
    }

    action = Processor.RulesAction.to_action(info, rules)

    Logger.info(inspect(action))

    assert action["action_type"] == info["action_type"] and
             action["type"] == "action"
  end
end
