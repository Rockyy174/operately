defmodule Operately.Operations.ResourceHubFolderCopyingTest do
  use Operately.DataCase

  setup ctx do
    ctx
    |> Factory.setup()
    |> Factory.add_space(:space)
    |> Factory.add_resource_hub(:hub, :space, :creator)
  end

  test "Copies folder with nested content", ctx do
    ctx = create_nested_content(ctx)

    Operately.Operations.ResourceHubFolderCopying.run(ctx.hub, ctx.folder1)
  end

  #
  # Helpers
  #

  defp create_nested_content(ctx) do
    ctx
    |> Factory.add_folder(:folder1, :hub)
    |> Factory.preload(:folder1, :node)
    |> Factory.add_document(:doc1, :hub, folder: :folder1)
    |> Factory.add_document(:doc2, :hub, folder: :folder1)
    |> Factory.add_file(:file1, :hub, folder: :folder1)
    |> Factory.add_file(:file2, :hub, folder: :folder1)
    |> Factory.add_link(:link1, :hub, folder: :folder1)
    |> Factory.add_link(:link2, :hub, folder: :folder1)
    |> Factory.add_folder(:folder2, :hub, :folder1)
    |> Factory.add_document(:doc3, :hub, folder: :folder2)
    |> Factory.add_file(:file3, :hub, folder: :folder2)
    |> Factory.add_link(:link3, :hub, folder: :folder2)
  end
end
