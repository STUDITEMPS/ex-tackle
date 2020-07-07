# Copyright 2019 Plataformatec
# Copyright 2020 Dashbit

# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

#    http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

# Copied from https://github.com/dashbitco/broadway_rabbitmq
defmodule Tackle.Backoff do
  @moduledoc false
  @compile :nowarn_deprecated_function

  alias Tackle.Backoff

  @default_type :rand_exp
  @min 1_000
  @max 30_000

  defstruct [:type, :min, :max, :state]

  def new(opts) do
    case Keyword.get(opts, :backoff_type, @default_type) do
      :stop ->
        nil

      type ->
        {min, max} = min_max(opts)
        new(type, min, max)
    end
  end

  def backoff(%Backoff{type: :rand, min: min, max: max, state: state} = s) do
    {backoff, state} = rand(state, min, max)
    {backoff, %Backoff{s | state: state}}
  end

  def backoff(%Backoff{type: :exp, min: min, state: nil} = s) do
    {min, %Backoff{s | state: min}}
  end

  def backoff(%Backoff{type: :exp, max: max, state: prev} = s) do
    require Bitwise
    next = min(Bitwise.<<<(prev, 1), max)
    {next, %Backoff{s | state: next}}
  end

  def backoff(%Backoff{type: :rand_exp, max: max, state: state} = s) do
    {prev, lower, rand_state} = state
    next_min = min(prev, lower)
    next_max = min(prev * 3, max)
    {next, rand_state} = rand(rand_state, next_min, next_max)
    {next, %Backoff{s | state: {next, lower, rand_state}}}
  end

  def reset(%Backoff{type: :rand} = s), do: s
  def reset(%Backoff{type: :exp} = s), do: %Backoff{s | state: nil}

  def reset(%Backoff{type: :rand_exp, min: min, state: state} = s) do
    {_, lower, rand_state} = state
    %Backoff{s | state: {min, lower, rand_state}}
  end

  ## Internal

  defp min_max(opts) do
    case {opts[:backoff_min], opts[:backoff_max]} do
      {nil, nil} -> {@min, @max}
      {nil, max} -> {min(@min, max), max}
      {min, nil} -> {min, max(min, @max)}
      {min, max} -> {min, max}
    end
  end

  defp new(_, min, _) when not (is_integer(min) and min >= 0) do
    raise ArgumentError, "minimum #{inspect(min)} not 0 or a positive integer"
  end

  defp new(_, _, max) when not (is_integer(max) and max >= 0) do
    raise ArgumentError, "maximum #{inspect(max)} not 0 or a positive integer"
  end

  defp new(_, min, max) when min > max do
    raise ArgumentError, "minimum #{min} is greater than maximum #{max}"
  end

  defp new(:rand, min, max) do
    %Backoff{type: :rand, min: min, max: max, state: seed()}
  end

  defp new(:exp, min, max) do
    %Backoff{type: :exp, min: min, max: max, state: nil}
  end

  defp new(:rand_exp, min, max) do
    lower = max(min, div(max, 3))
    %Backoff{type: :rand_exp, min: min, max: max, state: {min, lower, seed()}}
  end

  defp new(type, _, _) do
    raise ArgumentError, "unknown type #{inspect(type)}"
  end

  defp seed() do
    case rand_module() do
      :rand ->
        {:rand, :rand.seed_s(:exsplus)}

      :random ->
        {:random, random_seed()}
    end
  end

  defp rand_module() do
    {:ok, mods} = :application.get_key(:stdlib, :modules)

    if :rand in mods do
      :rand
    else
      :random
    end
  end

  defp random_seed() do
    {_, sec, micro} = :os.timestamp()
    hash = :erlang.phash2({self(), make_ref()})

    case :random.seed(hash, sec, micro) do
      :undefined -> Process.delete(:random_seed)
      prev -> Process.put(:random_seed, prev)
    end
  end

  defp rand({mod, state}, min, max) do
    {int, state} = apply(mod, :uniform_s, [max - min + 1, state])
    {int + min - 1, {mod, state}}
  end
end
