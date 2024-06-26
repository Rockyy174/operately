defmodule Operately.Access do
  import Ecto.Query, warn: false
  alias Operately.Repo

  alias Operately.Access.Context

  def list_contexts do
    Repo.all(Context)
  end

  def get_context!(id) when is_binary(id) do
    Repo.get!(Context, id)
  end

  def get_context!(attrs) when is_list(attrs) do
    Repo.get_by!(Context, attrs)
  end

  def create_context(attrs \\ %{}) do
    %Context{}
    |> Context.changeset(attrs)
    |> Repo.insert()
  end

  def update_context(%Context{} = context, attrs) do
    context
    |> Context.changeset(attrs)
    |> Repo.update()
  end

  def delete_context(%Context{} = context) do
    Repo.delete(context)
  end

  def change_context(%Context{} = context, attrs \\ %{}) do
    Context.changeset(context, attrs)
  end


  alias Operately.Access.Group

  def list_groups do
    Repo.all(Group)
  end

  def get_group!(id), do: Repo.get!(Group, id)

  def get_person_group(person) when is_struct(person, Operately.People.Person) do
    get_person_group(person.id)
  end

  # This query is not correct. We need to find a
  # way to query the person's individual group
  def get_person_group(person_id) when is_binary(person_id) do
    IO.puts("get_person_group/1 needs to be fixed")

    from(g in Group,
      join: m in assoc(g, :memberships),
      group_by: g.id,
      where: m.person_id == ^person_id,
      having: count(m.id) == 1,
      limit: 1,
      select: g
    )
    |> Repo.one()
  end

  def create_group(attrs \\ %{}) do
    %Group{}
    |> Group.changeset(attrs)
    |> Repo.insert()
  end

  def update_group(%Group{} = group, attrs) do
    group
    |> Group.changeset(attrs)
    |> Repo.update()
  end

  def delete_group(%Group{} = group) do
    Repo.delete(group)
  end

  def change_group(%Group{} = group, attrs \\ %{}) do
    Group.changeset(group, attrs)
  end


  alias Operately.Access.Binding

  def list_bindings do
    Repo.all(Binding)
  end

  def get_binding!(id), do: Repo.get!(Binding, id)

  def create_binding(attrs \\ %{}) do
    %Binding{}
    |> Binding.changeset(attrs)
    |> Repo.insert()
  end

  def update_binding(%Binding{} = binding, attrs) do
    binding
    |> Binding.changeset(attrs)
    |> Repo.update()
  end

  def delete_binding(%Binding{} = binding) do
    Repo.delete(binding)
  end

  def change_binding(%Binding{} = binding, attrs \\ %{}) do
    Binding.changeset(binding, attrs)
  end


  alias Operately.Access.GroupMembership

  def list_group_memberships do
    Repo.all(GroupMembership)
  end

  def get_group_membership!(id), do: Repo.get!(GroupMembership, id)

  def create_group_membership(attrs \\ %{}) do
    %GroupMembership{}
    |> GroupMembership.changeset(attrs)
    |> Repo.insert()
  end

  def update_group_membership(%GroupMembership{} = group_membership, attrs) do
    group_membership
    |> GroupMembership.changeset(attrs)
    |> Repo.update()
  end

  def delete_group_membership(%GroupMembership{} = group_membership) do
    Repo.delete(group_membership)
  end

  def change_group_membership(%GroupMembership{} = group_membership, attrs \\ %{}) do
    GroupMembership.changeset(group_membership, attrs)
  end
end
