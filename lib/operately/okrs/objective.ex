defmodule Operately.Okrs.Objective do
  use Ecto.Schema
  import Ecto.Changeset

  alias Operately.Alignments.Alignment

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "objectives" do
    has_many :key_results, Operately.Okrs.KeyResult, on_delete: :delete_all

    has_one :parent, Alignment, foreign_key: :child

    field :description, :string
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(objective, attrs) do
    objective
    |> cast(attrs, [:name, :description])
    |> put_assoc(:parent, attrs["aligns_with"])
    |> validate_required([:name, :description])
  end
end
