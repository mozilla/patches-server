defmodule Patches.CacheWindowTest do
  use ExUnit.Case
  doctest Patches.CacheWindow

  alias Patches.CacheWindow, as: CW

  test "supports any type that implements the `Window` protocol" do
    window =
      [1,5,10,23,2,15,6,9]
      |> Window.view(1, 5)

    assert window == [5,10,23,2,15]
  end

  test "initializes to provide over a given number of elements" do
  end
end
