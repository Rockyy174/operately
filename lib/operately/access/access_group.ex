defmodule Operately.Access.Group do
  use Operately.Schema

  schema "access_groups" do
    belongs_to :person, Operately.Groups.Group, foreign_key: :person_id
    belongs_to :group, Operately.Groups.Group, foreign_key: :group_id

    has_many :memberships, Operately.Access.GroupMembership, foreign_key: :access_group_id
    has_many :bindings, Operately.Access.Binding, foreign_key: :access_group_id

    timestamps()
  end

  def changeset(attrs) do
    changeset(%__MODULE__{}, attrs)
  end

  def changeset(group, attrs) do
    group
    |> cast(attrs, [:group_id, :person_id])
    |> validate_required([])
  end
end
