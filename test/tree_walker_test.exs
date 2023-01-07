defmodule TreeWalkerTest do
  use ExUnit.Case

  @path "test/dir"

  test "it streams all the paths" do
    assert TreeWalker.stream(@path) |> Enum.to_list() == [
             "test/dir/file_a.txt",
             "test/dir/dir_a/file_b.txt",
             "test/dir/dir_a/dir_b/file_c.txt",
             "test/dir/dir_a/dir_c/file_d.txt"
           ]
  end

  test "it includes the File.State in a tuple if include_stat is true" do
    list = TreeWalker.stream(@path, include_stat: true) |> Enum.to_list()
    first_element = Enum.at(list, 0)

    assert tuple_size(first_element) == 2
    assert elem(first_element, 0) == "test/dir/file_a.txt"
    assert is_struct(elem(first_element, 1), File.Stat)
  end

  test "it skips a directory if skip_dir returns true" do
    opts = [
      skip_dir: fn path -> String.contains?(path, "dir_b") end
    ]

    assert TreeWalker.stream(@path, opts) |> Enum.to_list() == [
             "test/dir/file_a.txt",
             "test/dir/dir_a/file_b.txt",
             "test/dir/dir_a/dir_c/file_d.txt"
           ]
  end

  test "it returns unsorted if sort is false" do
    opts = [sort: false]

    assert TreeWalker.stream(@path, opts) |> Enum.to_list() == [
             "test/dir/file_a.txt",
             "test/dir/dir_a/file_b.txt",
             "test/dir/dir_a/dir_b/file_c.txt",
             "test/dir/dir_a/dir_c/file_d.txt"
           ]
  end

  test "it throws if the starting path is not a directory" do
    assert_raise TreeWalker.Error, fn ->
      TreeWalker.stream("mix.exs") |> Stream.run()
    end
  end
end
