defmodule Features.ResourceHubLinkTest do
  use Operately.FeatureCase

  alias Operately.Support.Features.ResourceHubSteps, as: Steps
  alias Operately.Support.Features.ResourceHubLinkSteps, as: LinkSteps

  @link %{
    title: "Link",
    url: "http://localhost:4000",
    notes: "This is a link",
  }

  setup ctx, do: Steps.setup(ctx)

  describe "links" do
    feature "create link", ctx do
      ctx
      |> Steps.visit_resource_hub_page()
      |> LinkSteps.create_link(@link)
      |> LinkSteps.assert_link_content(@link)
      |> LinkSteps.assert_link_created_on_space_feed(@link.title)
      |> LinkSteps.assert_link_created_on_company_feed(@link.title)
      |> LinkSteps.assert_link_created_notification_sent(@link.title)
      |> LinkSteps.assert_link_created_email_sent()
    end

    feature "edit link", ctx do
      link = %{
        title: "Link (edited)",
        url: "http://localhost:3000",
        notes: "This is a link (also edited)",

        previous_title: @link.title,
        previous_url: @link.url,
      }

      ctx
      |> Steps.visit_resource_hub_page()
      |> LinkSteps.create_link(@link)
      |> LinkSteps.edit_link(link)
      |> LinkSteps.assert_link_content(link)
      |> LinkSteps.assert_link_edited_on_space_feed(link)
      |> LinkSteps.assert_link_edited_on_company_feed(link)
    end

    feature "delete link from content list", ctx do
      ctx
      |> Steps.visit_resource_hub_page()
      |> LinkSteps.create_link(@link)
      |> Steps.visit_resource_hub_page()
      |> LinkSteps.delete_link(@link.title)
      |> Steps.assert_zero_state()
      |> LinkSteps.assert_link_deleted_on_space_feed()
      |> LinkSteps.assert_link_deleted_on_company_feed()
      |> LinkSteps.assert_link_deleted_notification_sent()
      |> LinkSteps.assert_link_deleted_email_sent()
    end

    feature "deleting link from link page redirects to resource hub", ctx do
      ctx
      |> LinkSteps.given_link_exists()
      |> LinkSteps.visit_link_page()
      |> LinkSteps.delete_link()
      |> Steps.assert_page_is_resource_hub_root(name: "Resource hub")
      |> Steps.assert_zero_state("Resource hub")
    end

    feature "deleting link within folder from link page redirects to folder", ctx do
      ctx
      |> LinkSteps.given_link_within_nested_folders_exists()
      |> LinkSteps.visit_link_page()
      |> LinkSteps.delete_link()
      |> Steps.assert_page_is_folder_root(folder_key: :five)
      |> Steps.assert_zero_folder_state()
    end

    feature "link navigation works", ctx do
      ctx
      |> LinkSteps.given_link_within_nested_folders_exists()
      |> LinkSteps.visit_link_page()
      |> Steps.assert_navigation_links(["Product Space", "Resource hub", "one", "two", "three", "four", "five"])
      |> Steps.navigate_back("two")
      |> Steps.refute_navigation_links(["two", "three", "four", "five"])
      |> Steps.assert_navigation_links(["Product Space", "Resource hub", "one"])
      |> Steps.navigate_back("Resource hub")
      |> Steps.refute_navigation_links(["Resource hub", "one"])
      |> Steps.assert_navigation_links(["Product Space"])
    end
  end
end