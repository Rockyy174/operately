defmodule Operately.Activities.Content.PasswordFirstTimeChanged do
  use Operately.Activities.Content

  embedded_schema do
    field :invitatition_id, :string
    field :company_id, :string
    field :admin_name, :string
    field :admin_email, :string
    field :member_name, :string
    field :member_email, :string
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, __schema__(:fields))
    |> validate_required(__schema__(:fields))
  end

  def build(params) do
    changeset(params)
  end
end
