defmodule Operately.Mcp.RegisteredClient do
  use Operately.Schema

  alias Operately.Mcp.ClientMetadata
  alias Operately.Mcp.ClientMetadata.RedirectUri
  alias Operately.Repo

  @default_grant_types ["authorization_code", "refresh_token"]
  @default_response_types ["code"]

  schema "mcp_registered_clients" do
    field :client_id, :string
    field :client_name, :string
    field :client_uri, :string
    field :logo_uri, :string
    field :redirect_uris, {:array, :string}
    field :token_endpoint_auth_method, :string, default: "none"
    field :grant_types, {:array, :string}, default: @default_grant_types
    field :response_types, {:array, :string}, default: @default_response_types
    field :registered_at, :utc_datetime

    timestamps()
  end

  def changeset(registered_client, attrs) do
    registered_client
    |> cast(attrs, [
      :client_id,
      :client_name,
      :client_uri,
      :logo_uri,
      :redirect_uris,
      :token_endpoint_auth_method,
      :grant_types,
      :response_types,
      :registered_at
    ])
    |> validate_required([:client_id, :client_name, :redirect_uris, :token_endpoint_auth_method, :grant_types, :response_types, :registered_at])
    |> validate_length(:redirect_uris, min: 1, max: RedirectUri.max_redirect_uris())
    |> unique_constraint(:client_id)
  end

  def get_by_client_id(client_id) when is_binary(client_id) do
    Repo.get_by(__MODULE__, client_id: client_id)
  end

  def to_client_metadata(%__MODULE__{} = registered_client) do
    {:ok, metadata} =
      ClientMetadata.build(%{
        client_id: registered_client.client_id,
        client_name: registered_client.client_name,
        client_uri: registered_client.client_uri,
        logo_uri: registered_client.logo_uri,
        redirect_uris: registered_client.redirect_uris,
        token_endpoint_auth_method: registered_client.token_endpoint_auth_method
      })

    metadata
  end

  def default_grant_types, do: @default_grant_types
  def default_response_types, do: @default_response_types
end
