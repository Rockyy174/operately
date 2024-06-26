defmodule Operately.Operations.ProjectContributorAdditionTest do
  use Operately.DataCase
  use Operately.Support.Notifications

  import Ecto.Query, only: [from: 2]

  import Operately.CompaniesFixtures
  import Operately.PeopleFixtures
  import Operately.GroupsFixtures
  import Operately.ProjectsFixtures
  import Operately.AccessFixtures, only: [group_for_person_fixture: 1]

  alias Operately.Repo
  alias Operately.Projects
  alias Operately.Projects.Contributor
  alias Operately.Activities.Activity

  setup do
    company = company_fixture()
    creator = person_fixture_with_account(%{company_id: company.id})
    group = group_fixture(creator)

    contributor = person_fixture_with_account(%{company_id: company.id})
    project = project_fixture(%{company_id: company.id, creator_id: creator.id, group_id: group.id})

    group_for_person_fixture(contributor)

    {:ok, creator: creator, contributor: contributor, project: project}
  end

  test "ProjectContributorAddition operation creates project contributor", ctx do
    assert 2 == Repo.aggregate(Contributor, :count, :id)

    Operately.Operations.ProjectContributorAddition.run(ctx.creator, %{
      project_id: ctx.project.id,
      person_id: ctx.contributor.id,
      responsibility: "Developer",
      role: :contributor
    })

    assert 3 == Repo.aggregate(Contributor, :count, :id)

    contributor = Projects.get_contributor!(person_id: ctx.contributor.id, project_id: ctx.project.id)

    assert contributor.responsibility == "Developer"
    assert contributor.role == :contributor
  end

  test "ProjectContributorAddition operation creates activity and notification", ctx do
    Oban.Testing.with_testing_mode(:manual, fn ->
      Operately.Operations.ProjectContributorAddition.run(ctx.creator, %{
        project_id: ctx.project.id,
        person_id: ctx.contributor.id,
        responsibility: "Developer",
        role: :contributor
      })
    end)

    activity = from(a in Activity, where: a.action == "project_contributor_addition" and a.content["project_id"] == ^ctx.project.id) |> Repo.one()

    assert 0 == notifications_count()

    perform_job(activity.id)

    assert 1 == notifications_count()
    assert nil != fetch_notification(activity.id)
  end
end
