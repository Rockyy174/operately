defmodule Operately.Support.Features.ResourceHubSteps do
  use Operately.FeatureCase

  alias Operately.ResourceHubs.{ResourceHub, Node}

  step :setup, ctx do
    ctx =
      ctx
      |> Factory.setup()
      |> Factory.enable_feature("resource_hubs")
      |> Factory.add_space(:space)
      |> Factory.add_space_member(:other_user, :space)

    UI.login_as(ctx, ctx.creator)
  end

  step :visit_space_page, ctx do
    UI.visit(ctx, Paths.space_path(ctx.company, ctx.space))
  end

  step :visit_resource_hub_page, ctx, name \\ "Documents & Files" do
    {:ok, hub} = ResourceHub.get(:system, space_id: ctx.space.id, name: name)
    UI.visit(ctx, Paths.resource_hub_path(ctx.company, hub))
  end

  step :navigate_to_resource_hub_page, ctx do
    UI.click(ctx, testid: "documents-files")
  end

  step :navigate_back, ctx, name do
    UI.click_link(ctx, name)
  end

  step :leave_comment, ctx do
    ctx
    |> UI.click(testid: "add-comment")
    |> UI.fill_rich_text("This is a comment.")
    |> UI.click(testid: "post-comment")
    |> UI.refute_has(testid: "post-comment")
  end

  #
  # Assertions
  #

  step :assert_zero_state, ctx, name \\ "Documents & Files"  do
    ctx
    |> UI.assert_text(name)
    |> UI.assert_text("Ready for your first document")
    |> UI.assert_text("Your team's central hub for sharing documents, images, videos, and files. Click 'Add' to get started.")
  end

  step :assert_zero_folder_state, ctx do
    ctx
    |> UI.assert_text("Ready for your first document")
    |> UI.assert_text("This folder is empty. Click 'Add' to upload your first file.")
  end

  step :assert_zero_state_on_space_page, ctx do
    UI.find(ctx, UI.query(testid: "documents-files"), fn ctx ->
      ctx
      |> UI.assert_text("Documents & Files")
      |> UI.assert_text("A place to share rich text documents, images, videos, and other files")
    end)
  end

  step :assert_comments_count, ctx, attrs do
    UI.find(ctx, UI.query(testid: "node-#{attrs.index}"), fn ctx ->
      ctx
      |> UI.assert_text(attrs.count)
    end)
  end

  step :assert_navigation_links, ctx, links do
    UI.find(ctx, UI.query(testid: "navigation"), fn ctx ->
      Enum.reduce(links, ctx, fn link, ctx ->
        ctx
        |> UI.assert_text(link)
      end)
    end)
  end

  step :refute_navigation_links, ctx, links do
    Enum.reduce(links, ctx, fn link, ctx ->
      ctx
      |> UI.refute_text(link, testid: "navigation")
    end)
  end

  step :refute_document_present_in_files_list, ctx, document_name do
    ctx
    |> UI.refute_text(document_name)
  end

  step :assert_page_is_resource_hub_root, ctx, name: name do
    {:ok, hub} = ResourceHub.get(:system, space_id: ctx.space.id, name: name)

    ctx
    |> UI.assert_page(Paths.resource_hub_path(ctx.company, hub))
  end

  step :assert_page_is_folder_root, ctx, folder_key: key do
    ctx
    |> UI.assert_page(Paths.folder_path(ctx.company, ctx[key]))
  end

  #
  # Deleting resource
  #

  step :delete_resource, ctx, resource_name do
    resource_id = get_resource_id(resource_name)
    menu_id = UI.testid(["menu", resource_id])
    delete_id = UI.testid(["delete", resource_id])

    ctx
    |> UI.click(testid: menu_id)
    |> UI.click(testid: delete_id)
  end

  step :delete_resource, ctx do
    ctx
    |> UI.click(testid: "options-button")
    |> UI.click(testid: "delete-resource-link")
  end

  step :assert_resource_deleted, ctx, resource_name do
    ctx
    |> UI.refute_text(resource_name)
  end

  #
  # Helpers
  #

  defp get_resource_id(resource_name) do
    {:ok, node} = Node.get(:system, name: resource_name, opts: [preload: :document])

    cond do
      node.document -> Paths.document_id(node.document)
    end
  end
end
