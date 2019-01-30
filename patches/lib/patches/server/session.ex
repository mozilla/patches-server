defmodule Patches.Server.Session do
  @moduledoc """
  Manage a ledger of values retrieved from a cache.
  """

  @doc """
  Create a new session state tracking no retrieved values.
  """
  def init(bucket_names) do
    num = Enum.count(bucket_names)

    Enum.zip(bucket_names, 0..(num-1))
    |> Map.new
  end
end
