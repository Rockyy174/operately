defmodule Operately.Features.SpacesTest do
  use Operately.FeatureCase

  import Operately.GroupsFixtures
  import Operately.PeopleFixtures

  alias Operately.Access.Binding
  alias Operately.Support.Features.SpaceSteps, as: Steps

  setup ctx, do: Steps.setup(ctx)

  feature "listing existing space", ctx do
    ctx
    |> Steps.given_two_spaces_exists()
    |> Steps.visit_home()
    |> Steps.assert_all_spaces_are_listed()
    |> Steps.assert_privacy_indicator_is_visible()
  end

  feature "creating a new space", ctx do
    params = %{
      name: "Marketing",
      mission: "Let the world know about our products",
      color: "text-green-500",
      icon: "IconBolt"
    }

    ctx
    |> Steps.visit_home()
    |> Steps.click_on_add_space()
    |> Steps.fill_in_space_form(params)
    |> Steps.submit_space_form()
    |> Steps.assert_space_created(params)
    |> Steps.assert_creator_is_space_member(params)
    |> Steps.assert_space_creationg_visible_in_activity_feed(params)
  end

  feature "viewing space information", ctx do
    ctx
    |> Steps.given_a_space_exists()
    |> Steps.visit_home()
    |> Steps.click_on_space()
    |> Steps.assert_space_name_mission_and_privacy_indicator()
  end

  feature "joining a space", ctx do
    group = group_fixture(ctx.person, %{name: "Marketing", company_permissions: Binding.view_access()})
    person = person_fixture_with_account(%{full_name: "Mati Aharoni", company_id: ctx.company.id})

    admin = hd(Operately.Companies.list_admins(ctx.company.id))
    Operately.Companies.add_admin(admin, person.id)

    ctx
    |> UI.login_as(person)
    |> UI.visit(Paths.space_path(ctx.company, group))
    |> UI.click(testid: "join-space-button")
    |> UI.sleep(300)
    |> UI.visit(Paths.space_path(ctx.company, group))
    |> UI.assert_text("Mati joined the space")

    members = Operately.Groups.list_members(group)
    assert Enum.find(members, fn member -> member.id == ctx.person.id end) != nil
  end

  feature "listing projects in a space", ctx do
    ctx
    |> Steps.visit_home()
    |> Steps.given_a_space_exists()
    |> Steps.given_the_space_has_several_projects(["Project 1", "Project 2"])
    |> Steps.given_the_space_has_several_space_wide_projects(["Project 3", "Project 4"])
    |> Steps.when_clicking_on_projects_tab()
    |> Steps.assert_projects_are_listed(["Project 1", "Project 2", "Project 3", "Project 4"])
  end

  feature "editing space's name and purpose", ctx do
    group = group_fixture(ctx.person, %{name: "Marketing", mission: "Let the world know about our products"})

    ctx
    |> Steps.visit_home()
    |> UI.click(title: group.name)
    |> UI.click(testid: "space-settings")
    |> UI.click(testid: "edit-name-and-purpose")
    |> UI.fill_in(Query.text_field("Name"), with: "Marketing 2")
    |> UI.fill_in(Query.text_field("Purpose"), with: "Let the world know about our products 2")
    |> UI.click(testid: "save")
    |> UI.assert_has(Query.text("Marketing 2", count: 2))
    |> UI.assert_has(Query.text("Let the world know about our products 2"))
  end

  feature "adding space members", ctx do
    member1 = person_fixture_with_account(%{full_name: "Alex Aleksej", company_id: ctx.company.id})
    member2 = person_fixture_with_account(%{full_name: "Boby Brown", company_id: ctx.company.id})
    member3 = person_fixture_with_account(%{full_name: "Cathy Clarkson", company_id: ctx.company.id})

    members = [member1, member2, member3]

    ctx
    |> Steps.given_a_space_exists()
    |> Steps.add_new_members(members)
    |> Steps.assert_members_added(members)
    |> Steps.assert_members_added_notification_sent(members)
    |> Steps.assert_members_added_email_sent(members)
  end

  feature "removing space members", ctx do
    [space, member] = Steps.given_space_with_member_exists(ctx, %{
      person_name: "Mati Aharoni",
      space_name: "Marketing",
    })

    ctx
    |> Steps.visit_home()
    |> Steps.visit_access_management(space.name)
    |> Steps.remove_member(member)
    |> Steps.assert_member_removed(member)
  end
end
