defmodule Server do
  @moduledoc """
  The Patches Server is responsible for maintaining sessions for scanners.
  It tracks the session IDs for each active scanner and the platform on
  which that scanner is running.
  """

  @doc """
  Create a Server.

  Sessions are stored in a map whose keys are unique identifiers and whose
  values are pairs of:
  1. The platform being scanned and
  2. The index into a vulnerability list.
  """
  def new() do
    %{}
  end

  @doc """
  Perform a lookup into the server session list to get a {platform, index} pair
  representing the scanner owning the provided ID's current state.
  """
  def lookup(sessions, id) do
    Map.get(sessions, id)
  end

  @doc """
  Establish a new session for a scanner performing a scan for a particular platform.
  """
  def create_session(sessions, platform) when is_binary(platform) do
    id = generate_id(fn id -> not Map.has_key?(sessions, id) end)
    {id, Map.put(sessions, id, {platform, 0})}
  end

  @doc """
  Remove a session.
  """
  def terminate_session(sessions, id) do
    Map.delete(sessions, id)
  end

  @doc """
  Generate a new random hex ID of a particular length. The `unqiue` argument
  must be a predicate function that, given a generated ID, returns true if the
  ID is unique or else false if it is not.
  """
  defp generate_id(length \\ 32, unique) do
    id = genid(length)
    if unique.(id) do
      id
    else
      generate_id(length, unique)
    end
  end

  @doc """
  Generate a random hex string of a particular length.
  """
  defp genid(length) do
    source = "abcdef0123456789"
    rand_chars = Enum.map(1..length, fn _n ->
      source
      |> String.length
      |> (fn n -> n - 1 end).()
      |> :rand.uniform()
      |> (fn n -> String.at(source, n) end).()
    end)
    Enum.reduce(rand_chars, "", fn char, str -> str <> char end)
  end
end
