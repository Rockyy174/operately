defmodule Operately.Repo.Migrations.CreateMcpRegisteredClients do
  use Ecto.Migration

  def change do
    create table(:mcp_registered_clients, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :client_id, :string, null: false
      add :client_name, :string, null: false
      add :client_uri, :string
      add :logo_uri, :string
      add :redirect_uris, {:array, :string}, null: false
      add :token_endpoint_auth_method, :string, null: false, default: "none"
      add :grant_types, {:array, :string}, null: false, default: ["authorization_code", "refresh_token"]
      add :response_types, {:array, :string}, null: false, default: ["code"]
      add :registered_at, :utc_datetime, null: false

      timestamps()
    end

    create unique_index(:mcp_registered_clients, [:client_id])
  end
end
