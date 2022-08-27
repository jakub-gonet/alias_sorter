defmodule AliasSorter do
  @moduledoc """
  Sorts and groups aliases.

  ## Limitations

  - AliasSorter works on text and not on AST.
  - Grouped aliases spanning multiple lines have leading and trailing newline.
    This Elixir formatter behavior causes AliasSorter to consider it as a
    different group.
  """

  @behaviour Mix.Tasks.Format

  @formatter_opts ~w|file line_length locals_without_parens force_do_end_blocks|a

  # We match `alias X.Y`, `alias X.{Y, Z}`, `alias X, as: W` that are
  # placed at start of the line
  @module "(?:\\w+\\.)*\\w+"
  @modules_comma "(?:\\s*#{@module}\\s*(?:,|(?=})))+\\s*"
  @grouping_part "(?:\\.{#{@modules_comma}})"
  @as_part "(?:\\s*,\\s*as:\\s*\\w+)"
  @alias_regex ~r/^\ *alias #{@module}(?:#{@as_part}|#{@grouping_part}?)/m

  @spec features(keyword()) :: [extensions: [String.t()]]
  def features(_opts), do: [extensions: [".ex", ".exs"]]

  @spec format(String.t(), keyword()) :: String.t()
  def format(contents, opts) do
    formatter_config = Keyword.take(opts, @formatter_opts)

    contents
    |> find_alias_groups()
    |> Enum.map_join(&split_grouped/1)
    |> Code.format_string!(formatter_config)
    |> Kernel.++(["\n"])
    |> IO.iodata_to_binary()
  end

  defp find_alias_groups(contents) do
    group_aliases = fn part, {aliases, with_as_part} = acc ->
      cond do
        # we extract modules from aliases, treating aliases aliased by `:as` specially
        alias?(part) ->
          case extract_modules_from_aliases(part) do
            {:as, alias_} -> {:cont, {aliases, [alias_ | with_as_part]}}
            {:modules, modules} -> {:cont, {[modules | aliases], with_as_part}}
          end

        # we treat single newline as part of the group
        part == "\n" ->
          {:cont, acc}

        # we got multiple newlines or some other code so we dump gathered
        # aliases as a new group
        # this generates tuple containing previous aliases group and next code
        true ->
          {:cont, {{Enum.reverse(aliases), Enum.reverse(with_as_part)}, part}, {[], []}}
      end
    end

    dump_remaining = fn
      {[], []} ->
        {:cont, {[], []}}

      {aliases, with_as_part} ->
        {:cont, {Enum.reverse(aliases), Enum.reverse(with_as_part)}, {[], []}}
    end

    @alias_regex
    |> Regex.split(contents, include_captures: true)
    |> Enum.chunk_while({[], []}, group_aliases, dump_remaining)
    |> flatten_aliases_tuples()
  end

  defp split_grouped({aliases, with_as_part}) do
    aliases
    |> expand_aliases()
    |> split_to_module_parts()
    |> group_prefixes()
    |> join_prefixes(with_as_part)
  end

  defp split_grouped(code), do: code

  defp join_prefixes(grouped_aliases, with_as_part) do
    grouped_aliases
    |> Enum.flat_map(&join_alias_parts/1)
    |> Kernel.++(with_as_part)
    |> Enum.sort_by(&String.downcase/1)
    |> Enum.join("\n")
  end

  defp join_alias_parts({[], modules}) do
    Enum.map(modules, &"alias #{&1}")
  end

  defp join_alias_parts({prefix, [single_module]}) do
    ["alias " <> Enum.join(prefix ++ [single_module], ".")]
  end

  defp join_alias_parts({prefix, suffixes}) do
    sorted_suffixes = Enum.sort_by(suffixes, &String.downcase/1)

    ["alias #{Enum.join(prefix, ".")}.{#{Enum.join(sorted_suffixes, ", ")}}"]
  end

  # We only group by second to last part of alias.
  defp group_prefixes(aliases) do
    Enum.group_by(
      aliases,
      fn modules -> List.delete_at(modules, -1) end,
      fn value -> List.last(value) end
    )
  end

  defp split_to_module_parts(aliases) do
    Enum.map(aliases, &String.split(&1, "."))
  end

  # Transforms `"X.{Y,Z}"` to `"X.Y\nX.Z". Aliases are sorted alphabetically.
  defp expand_aliases(aliases) do
    aliases
    |> Enum.map(&expand_alias/1)
    |> List.flatten()
    |> Enum.uniq()
  end

  defp expand_alias(alias_) do
    alias_
    |> String.split(["{", "}", ","], trim: true)
    |> case do
      [main_part | grouped] when grouped != [] -> Enum.map(grouped, &(main_part <> &1))
      [single_alias] -> single_alias
    end
  end

  # Transforms list of tuples with aliases groups and code to flat list of
  # groups and code
  defp flatten_aliases_tuples(grouped) do
    grouped
    |> Enum.reduce([], fn
      {[], code}, acc -> [code | acc]
      {alias_group, code}, acc -> [code, alias_group | acc]
    end)
    |> Enum.reverse()
  end

  # Takes full alias like `alias A.B.{C, D}`
  # and extracts only modules part and type of alias
  # into tuple: {:modules, "A.B.{C,D}"}.
  #
  # We treat aliases with `as: ` specially because they can't be grouped.
  defp extract_modules_from_aliases(full_alias) do
    has_as_part =
      @as_part
      |> Regex.compile!()
      |> Regex.match?(full_alias)

    trimmed = String.trim(full_alias)
    "alias" <> modules = remove_whitespace(trimmed)

    if has_as_part do
      {:as, trimmed}
    else
      {:modules, modules}
    end
  end

  defp remove_whitespace(string), do: String.replace(string, [" ", "\n"], "")

  defp alias?(text) do
    text
    |> String.trim_leading()
    |> String.starts_with?("alias")
  end
end
