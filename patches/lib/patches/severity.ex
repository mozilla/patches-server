defmodule Patches.Severity do
  @moduledoc """
  Constants representing each level of severity that may be assigned to a
  vulnerability to describe the criticality of its impact on a system.
  """

  def unknown, do: 0
  def negligible, do: 1
  def low, do: 2
  def medium, do: 3
  def high, do: 4
  def critical, do: 5
  def urgent, do: 6
end
