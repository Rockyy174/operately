defmodule Operately.Mcp.Operations.ClientRegistrationTest do
  use Operately.DataCase, async: true

  import Mock

  alias Operately.Mcp
  alias Operately.Mcp.ClientMetadata
  alias Operately.Mcp.ClientMetadata.Cache

  @cursor_redirect_uri "cursor://anysphere.cursor-mcp/oauth/callback"

  setup do
    Cache.clear()
    :ok
  end

  test "registers a public client and returns RFC 7591 metadata" do
    assert {:ok, response} =
             Mcp.register_client(%{
               "client_name" => "Cursor",
               "redirect_uris" => [@cursor_redirect_uri],
               "token_endpoint_auth_method" => "none"
             })

    assert response.client_id =~ "opmd_"
    assert is_integer(response.client_id_issued_at)
    assert response.client_name == "Cursor"
    assert response.redirect_uris == [@cursor_redirect_uri]
    assert response.token_endpoint_auth_method == "none"
    assert response.grant_types == ["authorization_code", "refresh_token"]
    assert response.response_types == ["code"]
  end

  test "rejects confidential client registration" do
    assert {:error, :unsupported_client_authentication} =
             Mcp.register_client(%{
               "client_name" => "Private Client",
               "redirect_uris" => ["https://client.example.com/callback"],
               "token_endpoint_auth_method" => "client_secret_post"
             })

    assert {:error, :unsupported_client_authentication} =
             Mcp.register_client(%{
               "client_name" => "Private Client",
               "redirect_uris" => ["https://client.example.com/callback"],
               "client_secret" => "secret"
             })
  end

  test "rejects invalid redirect uris" do
    assert {:error, :invalid_redirect_uri} =
             Mcp.register_client(%{
               "client_name" => "Bad Client",
               "redirect_uris" => ["http://evil.example.com/callback"]
             })
  end

  test "resolves a dynamically registered client" do
    {:ok, response} =
      Mcp.register_client(%{
        "client_name" => "Cursor",
        "redirect_uris" => [@cursor_redirect_uri]
      })

    assert {:ok, metadata} = ClientMetadata.resolve(response.client_id)
    assert metadata.client_id == response.client_id
    assert metadata.client_name == "Cursor"
    assert metadata.redirect_uris == [@cursor_redirect_uri]
  end

  test "prefers allowlist metadata over dynamically registered clients for the same client_id" do
    {:ok, response} =
      Mcp.register_client(%{
        "client_name" => "Registered Client",
        "redirect_uris" => [@cursor_redirect_uri]
      })

    previous_clients = Application.get_env(:operately, :mcp_oauth_clients)

    Application.put_env(:operately, :mcp_oauth_clients, [
      %{
        client_id: response.client_id,
        client_name: "Allowlisted Client",
        redirect_uris: [@cursor_redirect_uri],
        token_endpoint_auth_method: "none"
      }
    ])

    on_exit(fn ->
      Application.put_env(:operately, :mcp_oauth_clients, previous_clients)
    end)

    assert {:ok, metadata} = ClientMetadata.resolve(response.client_id)
    assert metadata.client_name == "Allowlisted Client"
  end

  test "prefers cimd metadata over dynamically registered clients for the same client_id" do
    cimd_client_id = "https://client.example.com/oauth/client.json"

    {:ok, registered} =
      Mcp.register_client(%{
        "client_name" => "Registered Client",
        "redirect_uris" => ["https://client.example.com/callback"]
      })

    assert registered.client_id != cimd_client_id

    with_mock Operately.Mcp.ClientMetadata.Fetcher, [],
      fetch: fn client_id ->
        assert client_id == cimd_client_id

        {:ok,
         %{
           "client_id" => cimd_client_id,
           "client_name" => "CIMD Client",
           "redirect_uris" => ["https://client.example.com/callback"]
         }}
      end do
      assert {:ok, metadata} = ClientMetadata.resolve(cimd_client_id)
      assert metadata.client_name == "CIMD Client"
    end
  end
end
