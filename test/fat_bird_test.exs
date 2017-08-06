defmodule FatBirdTest do
  use ExUnit.Case
  doctest FatBird

  test "greets the world" do
    assert FatBird.hello() == :world
  end
end
