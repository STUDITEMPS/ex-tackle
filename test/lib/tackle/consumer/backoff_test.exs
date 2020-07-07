# Copyright 2019 Plataformatec
# Copyright 2020 Dashbit

# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

#    http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

# Copied from https://github.com/dashbitco/broadway_rabbitmq
defmodule Tackle.BackoffTest do
  use ExUnit.Case, async: true

  alias Tackle.Backoff

  @moduletag backoff_min: 1_000
  @moduletag backoff_max: 30_000

  @tag backoff_type: :exp
  test "exponential backoffs aways in [min, max]", context do
    backoff = new(context)
    {delays, _} = backoff(backoff, 20)

    assert Enum.all?(delays, fn delay ->
             delay >= context[:backoff_min] and delay <= context[:backoff_max]
           end)
  end

  @tag backoff_type: :exp
  test "exponential backoffs double until max", context do
    backoff = new(context)
    {delays, _} = backoff(backoff, 20)

    Enum.reduce(delays, fn next, prev ->
      assert div(next, 2) == prev or next == context[:backoff_max]
      next
    end)
  end

  @tag backoff_type: :exp
  test "exponential backoffs reset to min", context do
    backoff = new(context)
    {[delay | _], backoff} = backoff(backoff, 20)
    assert delay == context[:backoff_min]

    backoff = Backoff.reset(backoff)
    {[delay], _} = backoff(backoff, 1)
    assert delay == context[:backoff_min]
  end

  @tag backoff_type: :rand
  test "random backoffs aways in [min, max]", context do
    backoff = new(context)
    {delays, _} = backoff(backoff, 20)

    assert Enum.all?(delays, fn delay ->
             delay >= context[:backoff_min] and delay <= context[:backoff_max]
           end)
  end

  @tag backoff_type: :rand
  test "random backoffs are not all the same value", context do
    backoff = new(context)
    {delays, _} = backoff(backoff, 20)
    ## If the stars align this test could fail ;)
    refute Enum.all?(delays, &(hd(delays) == &1))
  end

  @tag backoff_type: :rand
  test "random backoffs repeat", context do
    backoff = new(context)
    assert backoff(backoff, 20) == backoff(backoff, 20)
  end

  @tag backoff_type: :rand_exp
  test "random exponential backoffs aways in [min, max]", context do
    backoff = new(context)
    {delays, _} = backoff(backoff, 20)

    assert Enum.all?(delays, fn delay ->
             delay >= context[:backoff_min] and delay <= context[:backoff_max]
           end)
  end

  @tag backoff_type: :rand_exp
  test "random exponential backoffs increase until a third of max", context do
    backoff = new(context)
    {delays, _} = backoff(backoff, 20)

    Enum.reduce(delays, fn next, prev ->
      assert next >= prev or next >= div(context[:backoff_max], 3)
      next
    end)
  end

  @tag backoff_type: :rand_exp
  test "random exponential backoffs repeat", context do
    backoff = new(context)
    assert backoff(backoff, 20) == backoff(backoff, 20)
  end

  @tag backoff_type: :rand_exp
  test "random exponential backoffs reset in [min, min * 3]", context do
    backoff = new(context)
    {[delay | _], backoff} = backoff(backoff, 20)
    assert delay in context[:backoff_min]..(context[:backoff_min] * 3)

    backoff = Backoff.reset(backoff)
    {[delay], _} = backoff(backoff, 1)
    assert delay in context[:backoff_min]..(context[:backoff_min] * 3)
  end

  ## Helpers

  def new(context) do
    Backoff.new(Enum.into(context, []))
  end

  defp backoff(backoff, n) do
    Enum.map_reduce(1..n, backoff, fn _, acc -> Backoff.backoff(acc) end)
  end
end
