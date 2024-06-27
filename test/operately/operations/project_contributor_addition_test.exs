defmodule Operately.Operations.ProjectContributorAdditionTest do
  use Operately.DataCase
  use Operately.Support.Notifications

  import Ecto.Query, only: [from: 2]

  import Operately.CompaniesFixtures
  import Operately.PeopleFixtures
  import Operately.GroupsFixtures
  import Operately.ProjectsFixtures

  alias Operately.Repo
  alias Operately.Access
  alias Operately.Access.Binding
  alias Operately.Projects
  alias Operately.Projects.Contributor
  alias Operately.Activities.Activity

  setup do
    company = company_fixture()
    creator = person_fixture_with_account(%{company_id: company.id})
    group = group_fixture(creator)

    contributor = person_fixture_with_account(%{company_id: company.id})
    project = project_fixture(%{company_id: company.id, creator_id: creator.id, group_id: group.id})

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

  test "ProjectContributorAddition operation creates access binding for contributor", ctx do
    assert nil == fetch_access_binding(ctx.project, ctx.contributor, 70)

    Operately.Operations.ProjectContributorAddition.run(ctx.creator, %{
      project_id: ctx.project.id,
      person_id: ctx.contributor.id,
      responsibility: "Developer",
      role: :contributor
    })

    assert nil != fetch_access_binding(ctx.project, ctx.contributor, 70)
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

  #
  # Helpers
  #

  defp fetch_access_binding(project, person, access_level) do
    context = Access.get_context!(project_id: project.id)
    group = Access.get_group!(person_id: person.id)

    from(b in Binding, where: b.access_context_id == ^context.id and b.access_group_id == ^group.id and b.access_level == ^access_level)
    |> Repo.one()
  end
end
