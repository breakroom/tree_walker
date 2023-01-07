defmodule TreeWalker do
  @moduledoc """
  TreeWalker provides a `Stream` style interface for recursively walking through
  directories and returning the file paths discovered.
  """

  defmodule Error do
    defexception [:message]
  end

  @doc """
  Returns a `Stream` of file paths discovered by walking through directories
  underneath the starting `path` provided.

  Accepts some options:

  * `skip_dir`: if provided, must be a function with a single argument,
    returning a boolean. This will be called with every directory discovered. The
    function will be passed the path of the directory, and must return `true` if
    the directory should be skipped, or `false` if the directory should be
    traversed. Defaults to `nil`.

  * `sort`: sorts the files inside a directory before returning them. Defaults to
    `false`.

  * `include_stat`: instead of returning a `String` for each path, returns a
    tuple of the `{path, %File.Stat{}}`. This is handy if you want to check for
    file sizes or permissions in a later stage, but can increase memory usage.
    Defaults to `false`.


  # Tips

  If you want to filter the files returned, use a subsequent `Stream.filter/2`
  or `Stream.reject/2` operation, such as:

  ```
  TreeWalker.stream(path)
  |> Stream.reject(&String.ends_with?(&1, ".json"))
  ```
  """
  def stream(path, opts \\ []) do
    Stream.resource(
      fn -> start_path(path) end,
      &do_walk(&1, opts),
      &noop/1
    )
  end

  defp start_path(path) do
    case File.stat!(path) do
      %File.Stat{type: :directory} -> [path]
      _ -> raise Error, "starting path is not a directory"
    end
  end

  defp do_walk([], _opts), do: {:halt, nil}

  defp do_walk([current_dir | next_dirs], opts) do
    skip_dir_fun = Keyword.get(opts, :skip_dir)
    sort = Keyword.get(opts, :sort, true)
    include_stat = Keyword.get(opts, :include_stat, false)

    {dir_paths, file_paths} = scan_paths(current_dir, skip_dir_fun, sort, include_stat)

    {file_paths, next_dirs ++ dir_paths}
  end

  defp noop(_), do: nil

  defp scan_paths(dir, skip_dir_fun, sort, include_stat) do
    if skip_dir?(dir, skip_dir_fun) do
      {[], []}
    else
      dir
      |> list_paths(sort)
      |> split_paths(include_stat)
    end
  end

  defp list_paths(path, sort) do
    File.ls!(path)
    |> maybe_sort(sort)
    |> Enum.map(&Path.join(path, &1))
  end

  defp split_paths(paths, include_stat) do
    {dir_paths, file_paths} =
      Enum.reduce(paths, {[], []}, fn path, {dir_paths, file_paths} ->
        %File.Stat{type: type} = stat = File.stat!(path)

        case type do
          :directory ->
            {[path | dir_paths], file_paths}

          :regular ->
            if include_stat do
              {dir_paths, [{path, stat} | file_paths]}
            else
              {dir_paths, [path | file_paths]}
            end
        end
      end)

    {:lists.reverse(dir_paths), :lists.reverse(file_paths)}
  end

  defp maybe_sort(list, true) do
    Enum.sort(list)
  end

  defp maybe_sort(list, false) do
    list
  end

  defp skip_dir?(_dir, nil), do: false

  defp skip_dir?(dir, fun) do
    fun.(dir) == true
  end
end
