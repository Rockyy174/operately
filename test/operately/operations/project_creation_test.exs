defmodule Operately.Operations.ProjectCreationTest do
  use Operately.DataCase

  import Operately.CompaniesFixtures
  import Operately.PeopleFixtures
  import Operately.GroupsFixtures
  import Operately.GoalsFixtures

  alias Operately.Repo
  alias Operately.Access
  alias Operately.Projects
  alias Operately.Projects.Project

  setup do
    company = company_fixture()
    creator = person_fixture_with_account(%{company_id: company.id})
    champion = person_fixture_with_account(%{company_id: company.id})
    reviewer = person_fixture_with_account(%{company_id: company.id})
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
end
