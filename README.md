# AliasSorter

Sorts and groups aliases.

## Installation

The package can be installed by adding `alias_sorter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:alias_sorter, "~> 0.1.0"}
  ]
end
```

## Usage

Add `AliasSorter` as a plugin in `.formatter.exs` file.

```elixir
# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  plugins: [AliasSorter]
]
```

[**Documentation**](https://hexdocs.pm/alias_sorter)
