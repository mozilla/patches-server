defmodule Patches.Server.Config do
  @moduledoc """
  A structure containing the data that a user can supply to configure the
  behaviour of a `Patches.Server`.
  """

  defstruct(
    max_active_sessions: 128,
    max_queued_sessions: 1024,
    active_session_timeout_seconds: 10 * 60,
    queued_session_timeout_seconds: 5 * 60, 
  )
end

defmodule Patches.Server.Session do
  @moduledoc """
  A structure representing a scanner session.
  """

  @enforce_keys [:id, :platform]
  defstruct [:id, :platform, :window_index]
end

defmodule Patches.Server do
  @moduledoc """
  Tracks sessions belonging to scanners requesting vulnerability information.
  """
end
