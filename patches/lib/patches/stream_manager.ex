defmodule Patches.StreamManager.SessionState do
  @moduledoc """
  """

  defstruct [
    :current_index,
    :window_length,
    :last_read_at,
  [
end

defmodule Patches.StreamManager do
  @moduledoc """
  An `Agent` responsible for managing cache windows over lists of
  vulnerabilities being streamed from a `Source`.
  """

  use Agent

  @doc """
  Start and link the `StreamManager`.
  """
  def start_link() do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end
end
