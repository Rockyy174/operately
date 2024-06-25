defmodule Operately.Operations.GroupMembersAddingTest do
  use Operately.DataCase

  import Operately.CompaniesFixtures
  import Operately.PeopleFixtures
  import Operately.GroupsFixtures

  alias Operately.Groups

  setup do
    company = company_fixture()
    creator = person_fixture_with_account(%{company_id: company.id})
    group = group_fixture(creator)

    people_ids = Enum.map(1..3, fn _ ->
      person = person_fixture(%{company_id: company.id})
      person.id
    end)


    {:ok, group: group, creator: creator, people_ids: people_ids}
  end

  test "GroupMembersAdding operation adds members to group", ctx do
    Operately.Operations.GroupMembersAdding.run(ctx.group, ctx.people_ids)

    members = Groups.list_members(ctx.group)
    people_ids = [ctx.creator.id | ctx.people_ids]

    Enum.each(members, fn member ->
      assert Enum.member?(people_ids, member.id)
    end)
  end

  test "GroupMembersAdding operation adds members to access group", _ctx do
    # to do
  end
end
