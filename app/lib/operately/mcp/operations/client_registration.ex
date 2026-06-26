defmodule Operately.Mcp.Operations.ClientRegistration do
  alias Operately.Mcp.ClientMetadata.RedirectUri
  alias Operately.Mcp.{RegisteredClient, Token}
  alias Operately.Repo

  @client_id_prefix "opmd_"

  @doc """
  Registers a new public OAuth client via Dynamic Client Registration (RFC 7591).
  """
  def register(params) when is_map(params) do
    with :ok <- reject_confidential_registration(params),
         {:ok, client_name} <- fetch_required_string(params, "client_name"),
         {:ok, redirect_uris} <- fetch_redirect_uris(params),
         :ok <- validate_grant_types(params),
         :ok <- validate_response_types(params),
         {:ok, token_endpoint_auth_method} <- fetch_token_endpoint_auth_method(params) do
      now = Token.now()
      client_id = Token.generate(@client_id_prefix)

      attrs = %{
        client_id: client_id,
        client_name: client_name,
        client_uri: fetch_optional_string(params, "client_uri"),
        logo_uri: fetch_optional_string(params, "logo_uri"),
        redirect_uris: redirect_uris,
        token_endpoint_auth_method: token_endpoint_auth_method,
        grant_types: fetch_grant_types(params),
        response_types: fetch_response_types(params),
        registered_at: now
      }

      case %RegisteredClient{} |> RegisteredClient.changeset(attrs) |> Repo.insert() do
        {:ok, registered_client} ->
          {:ok, registration_response(registered_client)}

        {:error, _changeset} ->
          {:error, :invalid_client_metadata}
      end
    end
  end

  def register(_), do: {:error, :invalid_client_metadata}

  defp registration_response(%RegisteredClient{} = registered_client) do
    %{
      client_id: registered_client.client_id,
      client_id_issued_at: DateTime.to_unix(registered_client.registered_at),
      client_name: registered_client.client_name,
      redirect_uris: registered_client.redirect_uris,
      token_endpoint_auth_method: registered_client.token_endpoint_auth_method,
      grant_types: registered_client.grant_types,
      response_types: registered_client.response_types
    }
  end

  defp reject_confidential_registration(params) do
    cond do
      Map.has_key?(params, "client_secret") ->
        {:error, :unsupported_client_authentication}

      fetch_optional_string(params, "token_endpoint_auth_method") in ["client_secret_post", "client_secret_basic", "private_key_jwt"] ->
        {:error, :unsupported_client_authentication}

      true ->
        :ok
    end
  end

  defp fetch_token_endpoint_auth_method(params) do
    case fetch_optional_string(params, "token_endpoint_auth_method") do
      nil -> {:ok, "none"}
      "none" -> {:ok, "none"}
      _ -> {:error, :unsupported_client_authentication}
    end
  end

  defp fetch_grant_types(params) do
    case Map.get(params, "grant_types") do
      nil -> RegisteredClient.default_grant_types()
      grant_types when is_list(grant_types) -> grant_types
      _ -> RegisteredClient.default_grant_types()
    end
  end

  defp fetch_response_types(params) do
    case Map.get(params, "response_types") do
      nil -> RegisteredClient.default_response_types()
      response_types when is_list(response_types) -> response_types
      _ -> RegisteredClient.default_response_types()
    end
  end

  defp validate_grant_types(params) do
    case Map.get(params, "grant_types") do
      nil ->
        :ok

      grant_types when is_list(grant_types) ->
        if "authorization_code" in grant_types do
          :ok
        else
          {:error, :invalid_client_metadata}
        end

      _ ->
        {:error, :invalid_client_metadata}
    end
  end

  defp validate_response_types(params) do
    case Map.get(params, "response_types") do
      nil ->
        :ok

      response_types when is_list(response_types) ->
        if "code" in response_types do
          :ok
        else
          {:error, :invalid_client_metadata}
        end

      _ ->
        {:error, :invalid_client_metadata}
    end
  end

  defp fetch_redirect_uris(params) do
    case Map.get(params, "redirect_uris") do
      uris when is_list(uris) ->
        case RedirectUri.validate_list(uris) do
          :ok -> {:ok, uris}
          {:error, reason} -> {:error, reason}
        end

      _ ->
        {:error, :invalid_redirect_uri}
    end
  end

  defp fetch_required_string(params, key) do
    case Map.get(params, key) do
      value when is_binary(value) and value != "" -> {:ok, value}
      _ -> {:error, :invalid_client_metadata}
    end
  end

  defp fetch_optional_string(params, key) do
    case Map.get(params, key) do
      value when is_binary(value) and value != "" -> value
      _ -> nil
    end
  end
end
