# TreeWalker

TreeWalker is an Elixir library to recursively walk through directories,
streaming the file paths discovered as it goes.

It can optionally skip directories or return `File.Stat` structs if enabled.

The full documentation is available at <https://hexdocs.pm/tree_walker>.

## Installation

The package can be installed by adding `tree_walker` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tree_walker, "~> 0.1.0"}
  ]
end
```

## Example usages

To find all the `.json` files in a repo, skipping the `.git` directory, you
might do something like:

```elixir
TreeWalker.stream(path, skip_dir: &String.ends_with?(&1, ".git"))
|> Stream.filter(&String.ends_with?(&1, ".json"))
|> Enum.to_list()
```
