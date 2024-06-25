defmodule Operately.Operations.GroupMembersAdding do
  import Ecto.Query, only: [from: 2]

  alias Ecto.Multi
  alias Operately.Repo
  alias Operately.Groups.Member
  alias Operately.Access.GroupMembership

  def run(group, people_ids) do
    Multi.new()
    |> insert_members(people_ids, group)
    |> insert_access_group_memberships(people_ids, group)
    |> Repo.transaction()
  end

  defp insert_members(multi, people_ids, group) do
    people_ids
    |> Enum.map(fn id ->
      Member.changeset(%Member{}, %{
        group_id: group.id,
        person_id: id
      })
    end)
    |> Enum.with_index()
    |> Enum.reduce(multi, fn ({changeset, index}, multi) ->
      Multi.insert(multi, Integer.to_string(index), changeset)
    end)
  end

  defp insert_access_group_memberships(multi, people_ids, group) do
    access_group_id = fetch_members_access_group_id(group)

    people_ids
    |> Enum.map(fn id ->
      GroupMembership.changeset(%{
        access_group_id: access_group_id,
        person_id: id,
      })
    end)
    |> Enum.with_index()
    |> Enum.reduce(multi, fn ({changeset, index}, multi) ->
      name = Integer.to_string(index) <> "-membership"

      Multi.insert(multi, name, changeset)
    end)
  end

  # This function is not correct. We need a proper way
  # to query the members access group
  defp fetch_members_access_group_id(group) do
    from(g in Operately.Access.Group,
      join: b in Operately.Access.Binding, on: b.access_group_id == g.id,
      where: g.group_id == ^group.id and b.access_level != 100,
      limit: 1,
      select: g.id
    )
    |> Repo.one()
  end
end
