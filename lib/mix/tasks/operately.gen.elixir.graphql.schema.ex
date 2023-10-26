defmodule Mix.Tasks.Operately.Gen.Elixir.Graphql.Schema do
  import Mix.Operately, only: [indent: 2, generate_file: 2, list_files: 3]

  def run(_args) do
    gen_activity_type_union()
    gen_graphql_schema()
  end

  def gen_activity_type_union() do
    types = list_files("lib/operately_web/graphql/types/activity_content_*.ex", :basename, exclude: [])

    generate_file("lib/operately_web/graphql/types/activity_content.ex", fn _ ->
      """
      defmodule OperatelyWeb.Graphql.Types.ActivityContent do
        #
        # This file is generated by: mix operately.gen.elixir.graphql.schema
        # Do not edit this file directly.
        #

        use Absinthe.Schema.Notation

        union :activity_content do
          types [
            #{Enum.map(types, fn type -> ":#{type}" end) |> Enum.join(",\n") |> indent(4)}
          ]

          resolve_type fn %{action: action}, _ ->
            String.to_atom("activity_content_#\{action\}")
          end
        end
      end
      """
    end)
  end

  def gen_graphql_schema() do
    generate_file("lib/operately_web/graphql/schema.ex", fn _ ->
      """
      defmodule OperatelyWeb.Graphql.Schema do
        #
        # This file is generated by: mix operately.gen.elixir.graphql.schema
        # Do not edit this file directly.
        #

        use Absinthe.Schema

        import_types Absinthe.Type.Custom

        # Types
        #{indent(gen_import_type_statements(Path.wildcard("lib/operately_web/graphql/types/*.ex")), 2)}

        # Queries
        #{indent(gen_import_type_statements(Path.wildcard("lib/operately_web/graphql/queries/*.ex")), 2)}

        # Mutations
        #{indent(gen_import_type_statements(Path.wildcard("lib/operately_web/graphql/mutations/*.ex")), 2)}

        # Subscriptions
        #{indent(gen_import_type_statements(Path.wildcard("lib/operately_web/graphql/subscriptions/*.ex")), 2)}

        query do
          #{indent(gen_import_field_statements(Path.wildcard("lib/operately_web/graphql/queries/*.ex"), "_queries"), 4)}
        end

        mutation do
          #{indent(gen_import_field_statements(Path.wildcard("lib/operately_web/graphql/mutations/*.ex"), "_mutations"), 4)}
        end

        subscription do
          #{indent(gen_import_field_statements(Path.wildcard("lib/operately_web/graphql/subscriptions/*.ex"), "_subscriptions"), 4)}
        end
      end
      """
    end)
  end

  def gen_import_type_statements(files) do
    files
    |> Enum.map(fn file -> path_to_module_name(file) end)
    |> Enum.map(fn module -> "import_types #{module}" end)
    |> Enum.join("\n")
  end

  def gen_import_field_statements(files, suffix) do
    files
    |> Enum.map(fn file -> filename(file) end)
    |> Enum.map(fn file -> Inflex.singularize(file) end)
    |> Enum.map(fn file -> "import_fields :#{file}#{suffix}" end)
    |> Enum.join("\n")
  end

  def path_to_module_name(path) do
    path 
    |> String.replace("lib/", "") 
    |> String.replace(".ex", "")
    |> String.split("/")
    |> Enum.map(fn part -> Macro.camelize(part) end)
    |> Enum.join(".")
  end

  def filename(path) do
    path |> String.split("/") |> List.last() |> String.replace(".ex", "")
  end
end