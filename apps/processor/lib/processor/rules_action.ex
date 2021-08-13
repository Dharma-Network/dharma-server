defmodule Processor.RulesAction do
  @moduledoc """
  This is the `Action` module.
  This module receives action info and rules and this information generates an action structure.
  """

  @doc """
  Transforms information based on action types to an action structure.
  """
  def to_action(info, rules, users) do
    action_type = info["action_type"]
    mod = String.to_atom("#{__MODULE__}.#{Macro.camelize(action_type)}")
    fun = String.to_atom(action_type)
    apply(mod, fun, [info, rules[action_type], users])
  end
end
