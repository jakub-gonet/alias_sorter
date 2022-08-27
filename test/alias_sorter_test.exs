defmodule AliasSorterTest do
  use ExUnit.Case

  @formatter_opts [
    extension: ".exs",
    file: "nofile",
    sigils: [],
    plugins: [AliasSorter],
    inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
  ]

  test "keeps newline at the end" do
    input = "defmodule T do end"

    output = """
    defmodule T do
    end
    """

    assert format(input) == output
    assert input |> format() |> String.ends_with?("\n")
  end

  test "works on empty files" do
    assert format("") == "\n"
  end

  test "works on files without aliases" do
    input = """
    defmodule T do
      def f do
        :f
      end
    end
    """

    assert format(input) == input
  end

  describe "sorting" do
    test "simple aliases" do
      input = """
      defmodule T do
        alias B
        alias A
      end
      """

      output = """
      defmodule T do
        alias A
        alias B
      end
      """

      assert format(input) == output
    end

    test "prefixed aliases" do
      input = """
      defmodule T do
        alias A.B
        alias A
      end
      """

      output = """
      defmodule T do
        alias A
        alias A.B
      end
      """

      assert format(input) == output
    end

    test "grouped aliases" do
      # in group
      input = """
      defmodule T do
        alias A.{B, A}
      end
      """

      output = """
      defmodule T do
        alias A.{A, B}
      end
      """

      assert format(input) == output
    end
  end

  describe "grouping" do
    test "simple aliases" do
      input = """
      defmodule T do
        alias A.A
        alias A.B
      end
      """

      output = """
      defmodule T do
        alias A.{A, B}
      end
      """

      assert format(input) == output
    end

    test "keeps aliases in different blocks not grouped" do
      input = """
      defmodule T do
        alias A.A

        alias A.B
      end
      """

      assert format(input) == input
    end

    test "doesn't work on imports" do
      input = """
      defmodule T do
        import A.A
        import A.B
      end
      """

      assert format(input) == input
    end
  end

  describe "deduplicating" do
    test "inside a group" do
      input = """
      defmodule T do
        alias A.{A, A}
      end
      """

      output = """
      defmodule T do
        alias A.A
      end
      """

      assert format(input) == output
    end

    test "inside a group with non sequenced duplicates" do
      input = """
      defmodule T do
        alias A.{A, B, A}
      end
      """

      output = """
      defmodule T do
        alias A.{A, B}
      end
      """

      assert format(input) == output
    end

    test "across aliases" do
      input = """
      defmodule T do
        alias A
        alias B
        alias A
      end
      """

      output = """
      defmodule T do
        alias A
        alias B
      end
      """

      assert format(input) == output
    end
  end

  describe "comments" do
    test "are preserved" do
      input = """
      defmodule T do
        # comment about alias A.A
        alias A.A
        alias A.B
      end
      """

      output = """
      defmodule T do
        # comment about alias A.A
        alias A.{A, B}
      end
      """

      assert format(input) == output
    end

    test "prevents grouping" do
      input = """
      defmodule T do
        alias A.A # comment about alias A.A
        alias A.B
      end
      """

      output = """
      defmodule T do
        # comment about alias A.A
        alias A.A
        alias A.B
      end
      """

      assert format(input) == output
    end
  end

  describe "code" do
    test "prevents grouping" do
      input = """
      defmodule T do
        alias A.A

        def f do
          alias A.B
        end
      end
      """

      assert format(input) == input
    end
  end

  describe "aliased aliases" do
    test "aren't grouped" do
      input = """
      defmodule T do
        alias A.A, as: AA
        alias A.B
      end
      """

      assert format(input) == input
    end

    test "aren't deduplicated" do
      input = """
      defmodule T do
        alias A.A
        alias A.A, as: AA
        alias A.A, as: AAA
      end
      """

      assert format(input) == input
    end
  end

  defp format(input), do: AliasSorter.format(input, @formatter_opts)
end
