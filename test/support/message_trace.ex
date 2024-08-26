defmodule Support.MessageTrace do
  # we should reimplement this with something nicer
  # like an in memory queue

  def save(message, trace_name) do
    File.write("/tmp/#{trace_name}", message, [:append])
  end

  def clear(trace_name) do
    File.rm_rf("/tmp/#{trace_name}")
  end

  def content(trace_name) do
    File.read!("/tmp/#{trace_name}")
  end
end
