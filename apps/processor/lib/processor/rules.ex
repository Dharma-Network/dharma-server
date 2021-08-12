defmodule Processor.Rules do
  @moduledoc """
  Encapsulate the logic of evaluating an action to dharma.
  In order to be as adaptable as possible, this module assumes that the info that is provided to the only public function comes in a pre-prepared structure that is explained in more detail in the documentation of `evaluate_rules`.
  """

  @doc """
  `info` is a map that has keys corresponding to the the private functions defined in this module. If `info` contains a key called `number_of_lines` then `evaluate_rules` will evaluate the corresponding value into a dharma reward.
  """
  def evaluate_rules(info, reward_maps, action_type) do
    mod = String.to_atom("#{__MODULE__}." <> Macro.camelize(action_type))

    info
    |> Enum.reduce_while({0, %{}}, fn {k, v}, {r, map} ->
      case apply(mod, String.to_atom(k), [v, reward_maps[k]]) do
        {id, "abort"} -> {:halt, {0, id}}
        {id, reward} -> {:cont, {r + reward, Map.put(map, id, reward)}}
      end
    end)
  end
end
