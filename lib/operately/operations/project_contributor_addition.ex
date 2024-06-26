defmodule Operately.Operations.ProjectContributorAddition do
  alias Ecto.Multi
  alias Operately.Repo
  alias Operately.Activities
  alias Operately.Access
  alias Operately.Access.Binding

  def run(author, attrs) do
    changeset = Operately.Projects.Contributor.changeset(attrs)

    Multi.new()
    |> Multi.insert(:contributor, changeset)
    |> insert_contributor_binding(attrs)
    |> insert_activity(author)
    |> Repo.transaction()
    |> Repo.extract_result(:contributor)
  end

  defp insert_contributor_binding(multi, attrs) do
    Multi.insert(multi, :contributor_binding, fn _ ->
      access_group = Access.get_person_group(attrs.person_id)
      access_context = Access.get_context!(project_id: attrs.project_id)

      Binding.changeset(%{
        access_group_id: access_group.id,
        access_context_id: access_context.id,
        access_level: 70,
      })
    end)
  end

  defp insert_activity(multi, author) do
    Activities.insert_sync(multi, author.id, :project_contributor_addition, fn %{contributor: contributor} ->
      %{
        company_id: author.company_id,
        project_id: contributor.project_id,
        person_id: contributor.person_id,
        contributor_id: contributor.id,
        responsibility: contributor.responsibility,
        role: Atom.to_string(:contributor)
      }
    end)
  end
end
