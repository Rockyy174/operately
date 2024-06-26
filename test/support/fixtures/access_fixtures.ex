defmodule Operately.AccessFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Operately.Access` context.
  """

  def context_fixture(attrs \\ %{}) do
    {:ok, context} =
      attrs
      |> Enum.into(%{})
      |> Operately.Access.create_context()

    context
  end

  def group_fixture(attrs \\ %{}) do
    {:ok, group} =
      attrs
      |> Enum.into(%{})
      |> Operately.Access.create_group()

    group
  end

  # Temporary: in the near future, when a group is
  # automatically created for a user, this fixture
  # can be deleted.
  def group_for_person_fixture(person) do
    group = group_fixture()

    group_membership_fixture(%{
      access_group_id: group.id,
      person_id: person.id,
    })

    group
  end

  def binding_fixture(attrs \\ %{}) do
    {:ok, binding} =
      attrs
      |> Enum.into(%{
        access_level: 100,
      })
      |> Operately.Access.create_binding()

    binding
  end

  def group_membership_fixture(attrs \\ %{}) do
    {:ok, group_membership} =
      attrs
      |> Enum.into(%{})
      |> Operately.Access.create_group_membership()

    group_membership
  end
end
