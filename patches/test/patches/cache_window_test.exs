defmodule Patches.CacheWindowTest do
  use ExUnit.Case
  doctest Patches.CacheWindow

  alias Patches.CacheWindow

  test "initializes to provide a view over a given number of elements" do
    list =
      [1,2,3,4,5,6,7]

    %{ collection: coll, view: view } =
      CacheWindow.init(list, 3)

    assert coll == list
    assert view == Enum.take(list, 3)
  end

  test "can update the collection" do
    list =
      [1,2,3,4,5,6,7]

    %{ collection: coll } =
      CacheWindow.init(list, 3)
      |> CacheWindow.update(fn collection ->
          Enum.filter(collection, fn n -> Integer.mod(n, 2) == 0 end)
      end)

    assert coll == [2,4,6]
  end
end
