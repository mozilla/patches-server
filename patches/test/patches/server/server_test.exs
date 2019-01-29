defmodule Patches.ServerTest do
  use ExUnit.Case
  doctest Patches.Server

  alias Patches.Server, as: Srv

  test "creates unqiue identifiers for sessions" do
    state = Srv.new()
    ids = cycle_and_collect(35, state, fn state -> Srv.create_session(state, "") end)

    all_ids_unique =
      for x <- 0..34,
          y <- 0..34,
          x != y,
          do: Enum.at(ids, x) != Enum.at(ids, y)

    assert all_ids_unique 
  end

  defp cycle_and_collect(n, init, func, acc \\ []) do
    {collectable, next_init} = func.(init)
    if n <= 0 do
      Enum.reverse([ collectable | acc ])
    else
      cycle_and_collect(n - 1, next_init, func, [ collectable | acc ])
    end
  end
end
