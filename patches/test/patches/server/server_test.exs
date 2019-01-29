defmodule Patches.ServerTest do
  use ExUnit.Case
  doctest Patches.Server

  alias Patches.Server, as: Srv

  test "creates unqiue identifiers for sessions" do
    state = Srv.new()
    {ids, _state} = cycle_and_collect(35, state, fn state -> Srv.create_session(state, "") end)

    all_ids_unique =
      for x <- 0..34,
          y <- 0..34,
          x != y,
          do: Enum.at(ids, x) != Enum.at(ids, y)

    assert all_ids_unique 
  end

  test "handles the full lifecycle of sessions" do
    {ids, state} = cycle_and_collect(3, Srv.new(), fn state -> Srv.create_session(state, "") end)
    [ test_id | _ids ] = ids

    assert Srv.lookup(state, test_id) != nil

    state = Srv.terminate_session(state, test_id)

    assert Srv.lookup(state, test_id) == nil
  end

  @doc """
  Given a function `func` that returns `{value, next_init}`, calls `func`
  `n` times, first with `init`, and returns
  `{[value1, value2, ...], last_init}`.
  """
  defp cycle_and_collect(n, init, func, acc \\ []) do
    {collectable, next_init} = func.(init)
    if n <= 0 do
      {Enum.reverse([ collectable | acc ]), next_init}
    else
      cycle_and_collect(n - 1, next_init, func, [ collectable | acc ])
    end
  end
end
