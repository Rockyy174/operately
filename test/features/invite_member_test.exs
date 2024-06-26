defmodule Operately.Features.InviteMemberTest do
  use Operately.FeatureCase

  import Operately.CompaniesFixtures
  import Operately.PeopleFixtures
  import Operately.InvitationsFixtures

  alias Operately.Support.Features.UI
  alias Operately.Support.Features.InviteMemberSteps, as: Steps

  setup ctx do
    company = company_fixture()
    admin = person_fixture_with_account(%{company_id: company.id, full_name: "John Admin", company_role: :admin})

    #
    # Although currently not supported, ideally UI.login_as
    # should be moved out of setup so that when we test how
    # the user resets their password, no one is logged in
    #
    ctx = UI.login_as(ctx, admin)
    ctx = Map.merge(ctx, %{company: company, admin: admin})

    {:ok, ctx}
  end

  @new_member %{
    fullName: "John Doe",
    email: "john@some-company.com",
    title: "Developer",
    password: "Aa12345#&!123",
  }

  feature "admin account can invite members", ctx do
    ctx
    |> Steps.navigate_to_invitation_page
    |> Steps.invite_member(@new_member)
    |> Steps.assert_member_invited
  end

  feature "new member can reset their password", ctx do
    member = person_fixture_with_account(%{company_id: ctx.company.id, full_name: @new_member[:fullName], email: @new_member[:email]})
    invitation = invitation_fixture(%{member_id: member.id, admin_id: ctx.admin.id})
    token = invitation_token_fixture_unhashed(invitation.id)

    path = "/first-time-login?token=" <> token

    ctx
    |> UI.visit(path)
    |> Steps.assert_wrong_password(@new_member)
    |> Steps.change_password(@new_member[:password])
    |> UI.assert_page("/")
    |> Steps.assert_password_changed(@new_member)
  end
end
