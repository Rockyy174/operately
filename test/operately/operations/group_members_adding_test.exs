defmodule Operately.Operations.GroupMembersAddingTest do
  use Operately.DataCase

  import Ecto.Query, only: [from: 2]

  import Operately.CompaniesFixtures
  import Operately.PeopleFixtures
  import Operately.GroupsFixtures

  alias Operately.Repo
  alias Operately.Groups

  @members_access_level 40

  setup do
    company = company_fixture()
    creator = person_fixture_with_account(%{company_id: company.id})
    group = group_fixture(creator)

    people_ids = Enum.map(1..3, fn _ ->
      person = person_fixture(%{company_id: company.id})
      {person.id, @members_access_level}
    end)

    {:ok, group: group, creator: creator, people_ids: people_ids}
  end

  test "GroupMembersAdding operation adds members to group", ctx do
    Operately.Operations.GroupMembersAdding.run(ctx.group, ctx.people_ids)

    members = Groups.list_members(ctx.group)
    people_ids = [ctx.creator.id | Enum.map(ctx.people_ids, fn {id, _} -> id end)]

    Enum.each(members, fn member ->
      assert Enum.member?(people_ids, member.id)
    end)
  end

  test "GroupMembersAdding operation adds members to access group", ctx do
    Enum.each(ctx.people_ids, fn {person_id, _} ->
      assert nil == fetch_members_group(person_id, ctx.group.id)
    end)

    Operately.Operations.GroupMembersAdding.run(ctx.group, ctx.people_ids)

    Enum.each(ctx.people_ids, fn {person_id, _} ->
      group = fetch_members_group(person_id, ctx.group.id)

      assert group != nil
      assert hd(group.bindings).access_level == @members_access_level
    end)
  end

  #
  # Helpers
  #

  defp fetch_members_group(person_id, group_id) do
    from(g in Operately.Access.Group,
      join: m in assoc(g, :memberships),
      where: m.person_id == ^person_id and g.group_id == ^group_id,
      preload: :bindings,
      select: g
    )
    |> Repo.one()
  end
end
