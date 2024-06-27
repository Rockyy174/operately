defmodule Operately.Access.QueriesTest do
  use Operately.DataCase

  import Ecto.Query, only: [from: 2]

  import Operately.CompaniesFixtures
  import Operately.PeopleFixtures
  import Operately.GroupsFixtures
  import Operately.ProjectsFixtures

  alias Operately.Repo
  alias Operately.Projects.Project
  alias Operately.Access
  alias Operately.Access.Binding

  setup do
    {company, admin} = create_company_and_admin()

    creator = person_fixture(%{company_id: company.id})
    champion = person_fixture(%{company_id: company.id})
    reviewer = person_fixture(%{company_id: company.id})

    group = group_fixture(creator)
    project = project_fixture(%{company_id: company.id, creator_id: creator.id, champion_id: champion.id, reviewer_id: reviewer.id, group_id: group.id, creator_is_contributor: "no"})

    {:ok, company: company, project: project, admin: admin, creator: creator, champion: champion, reviewer: reviewer}
  end

  test "query project", ctx do
    another_user = person_fixture(%{company_id: ctx.company.id})

    assert nil != query_project(ctx.project, ctx.champion)
    assert nil != query_project(ctx.project, ctx.reviewer)
    assert nil == query_project(ctx.project, ctx.creator)
    assert nil == query_project(ctx.project, ctx.admin)
    assert nil == query_project(ctx.project, another_user)

    assert nil != query_project_with_space(ctx.project, ctx.champion)
    assert nil != query_project_with_space(ctx.project, ctx.reviewer)
    assert nil != query_project_with_space(ctx.project, ctx.creator)
    assert nil == query_project_with_space(ctx.project, ctx.admin)
    assert nil == query_project_with_space(ctx.project, another_user)

    assert nil != query_project_with_space_and_company(ctx.project, ctx.champion)
    assert nil != query_project_with_space_and_company(ctx.project, ctx.reviewer)
    assert nil != query_project_with_space_and_company(ctx.project, ctx.creator)
    assert nil != query_project_with_space_and_company(ctx.project, ctx.admin)
    assert nil == query_project_with_space_and_company(ctx.project, another_user)
  end

  #
  # Queries
  #

  defp query_project(project, person) do
    from(p in Project,
      join: c in assoc(p, :access_context),
      join: b in assoc(c, :bindings),
      join: g in assoc(b, :access_group),
      join: m in assoc(g, :memberships),
      where: p.id == ^project.id and m.person_id == ^person.id and b.access_level >= 70,
      distinct: true,
      select: p
    )
    |> Repo.one()
  end

  defp query_project_with_space(project, person) do
    from(p in Project,
      join: p_ac in assoc(p, :access_context),
      join: p_b in assoc(p_ac, :bindings),
      join: p_g in assoc(p_b, :access_group),
      join: p_m in assoc(p_g, :memberships),

      join: s in assoc(p, :group),
      join: s_ac in assoc(s, :access_context),
      join: s_b in assoc(s_ac, :bindings),
      join: s_g in assoc(s_b, :access_group),
      join: s_m in assoc(s_g, :memberships),

      where: p.id == ^project.id and (
        (p_m.person_id == ^person.id and p_b.access_level >= 70) or
        (s_m.person_id == ^person.id and s_b.access_level >= 70)
      ),
      distinct: true,
      select: p
    )
    |> Repo.one()
  end

  defp query_project_with_space_and_company(project, person) do
    from(p in Project,
      join: p_ac in assoc(p, :access_context),
      join: p_b in assoc(p_ac, :bindings),
      join: p_g in assoc(p_b, :access_group),
      join: p_m in assoc(p_g, :memberships),

      join: s in assoc(p, :group),
      join: s_ac in assoc(s, :access_context),
      join: s_b in assoc(s_ac, :bindings),
      join: s_g in assoc(s_b, :access_group),
      join: s_m in assoc(s_g, :memberships),

      join: c in assoc(p, :company),
      join: c_ac in assoc(c, :access_context),
      join: c_b in assoc(c_ac, :bindings),
      join: c_g in assoc(c_b, :access_group),
      join: c_m in assoc(c_g, :memberships),

      where: p.id == ^project.id and (
        (p_m.person_id == ^person.id and p_b.access_level >= 70) or
        (s_m.person_id == ^person.id and s_b.access_level >= 70) or
        (c_m.person_id == ^person.id and c_b.access_level >= 70)
      ),
      distinct: true,
      select: p
    )
    |> Repo.one()
  end

  #
  # Helpers
  #

  defp create_company_and_admin do
    company = company_fixture() |> Repo.preload(:access_context)

    admin = person_fixture(%{company_id: company.id})
    admin_group = Access.get_group(person_id: admin.id)

    Binding.changeset(%{
      access_group_id: admin_group.id,
      access_context_id: company.access_context.id,
      access_level: 100,
    })
    |> Repo.insert()

    {company, admin}
  end
end
