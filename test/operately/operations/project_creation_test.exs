defmodule Operately.Operations.ProjectCreationTest do
  use Operately.DataCase

  import Ecto.Query, only: [from: 2]

  import Operately.CompaniesFixtures
  import Operately.PeopleFixtures
  import Operately.GroupsFixtures
  import Operately.GoalsFixtures
  import Operately.AccessFixtures, only: [group_for_person_fixture: 1]

  alias Operately.Repo
  alias Operately.Access
  alias Operately.Access.Binding
  alias Operately.Projects
  alias Operately.Projects.Project

  setup do
    company = company_fixture()

    creator = person_fixture_with_account(%{company_id: company.id})
    group_for_person_fixture(creator)

    champion = person_fixture_with_account(%{company_id: company.id})
    group_for_person_fixture(champion)

    reviewer = person_fixture_with_account(%{company_id: company.id})
    group_for_person_fixture(reviewer)

    group = group_fixture(creator)
    goal = goal_fixture(creator, %{space_id: group.id, targets: []})

    {:ok, company: company, group: group, goal: goal, creator: creator, champion: champion, reviewer: reviewer}
  end

  test "ProjectCreation operation creates project and contributors", ctx do
    assert 0 == Repo.aggregate(Project, :count, :id)

    {:ok, project_one} = %Operately.Operations.ProjectCreation{
      company_id: ctx.company.id,
      name: "project 1",
      champion_id: ctx.champion.id,
      reviewer_id: ctx.reviewer.id,
      creator_id: ctx.creator.id,
      creator_role: nil,
      creator_is_contributor: "no",
      visibility: "everyone",
      group_id: ctx.group.id,
      goal_id: ctx.goal.id,
    }
    |> Operately.Operations.ProjectCreation.run()
    contributors = Projects.list_project_contributors(project_one)

    assert 1 == Repo.aggregate(Project, :count, :id)
    refute project_one.private

    assert 2 == length(contributors)
    assert ctx.champion == Projects.get_champion(project_one)
    assert ctx.reviewer == Projects.get_reviewer(project_one)

    {:ok, project_two} = %Operately.Operations.ProjectCreation{
      company_id: ctx.company.id,
      name: "project 1",
      champion_id: ctx.champion.id,
      reviewer_id: ctx.reviewer.id,
      creator_id: ctx.creator.id,
      creator_role: "manager",
      creator_is_contributor: "yes",
      visibility: "invite",
      group_id: ctx.group.id,
      goal_id: ctx.goal.id,
    }
    |> Operately.Operations.ProjectCreation.run()
    contributors = Projects.list_project_contributors(project_two)

    assert 2 == Repo.aggregate(Project, :count, :id)
    assert project_two.private

    assert 3 == length(contributors)
    assert ctx.champion == Projects.get_champion(project_two)
    assert ctx.reviewer == Projects.get_reviewer(project_two)
    assert ctx.creator == Projects.get_person_by_role(project_two, :contributor)
  end

  test "ProjectCreation operation creates access context", ctx do
    {:ok, project} = %Operately.Operations.ProjectCreation{
      company_id: ctx.company.id,
      name: "project 1",
      champion_id: ctx.champion.id,
      reviewer_id: ctx.reviewer.id,
      creator_id: ctx.creator.id,
      creator_role: nil,
      creator_is_contributor: "no",
      visibility: "everyone",
      group_id: ctx.group.id,
      goal_id: ctx.goal.id,
    }
    |> Operately.Operations.ProjectCreation.run()

    assert nil != Access.get_context!(project_id: project.id)
  end

  test "ProjectCreation operation creates access bindings for champion, reviewer and creator", ctx do
    {:ok, project} = %Operately.Operations.ProjectCreation{
      company_id: ctx.company.id,
      name: "project 1",
      champion_id: ctx.champion.id,
      reviewer_id: ctx.reviewer.id,
      creator_id: ctx.creator.id,
      creator_role: "manager",
      creator_is_contributor: "yes",
      visibility: "invite",
      group_id: ctx.group.id,
      goal_id: ctx.goal.id,
    }
    |> Operately.Operations.ProjectCreation.run()

    assert nil != fetch_access_binding(project, ctx.creator, 70)
    assert nil != fetch_access_binding(project, ctx.champion, 100)
    assert nil != fetch_access_binding(project, ctx.reviewer, 100)
  end

  #
  # Helpers
  #

  defp fetch_access_binding(project, person, access_level) do
    context = Access.get_context!(project_id: project.id)
    group = Access.get_person_group(person)

    from(b in Binding, where: b.access_context_id == ^context.id and b.access_group_id == ^group.id and b.access_level == ^access_level)
    |> Repo.one()
  end
end
