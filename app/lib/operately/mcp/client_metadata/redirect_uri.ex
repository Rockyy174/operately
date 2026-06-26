defmodule Operately.Mcp.ClientMetadata.RedirectUri do
  @moduledoc """
  Validates redirect URIs for Dynamic Client Registration.
  """

  @localhost_hosts ["localhost", "127.0.0.1", "::1"]
  @max_redirect_uris 10
  @denied_schemes ~w(javascript data file vbscript)

  @doc """
  Returns the maximum number of redirect URIs allowed per DCR registration.
  """
  def max_redirect_uris, do: @max_redirect_uris

  @doc """
  Returns `:ok` when the URI is allowed for DCR registration.
  """
  def valid?(uri) when is_binary(uri) do
    case validate(uri) do
      :ok -> true
      {:error, _} -> false
    end
  end

  @doc """
  Validates a list of redirect URIs for DCR registration.
  """
  def validate_list(uris) when is_list(uris) do
    cond do
      uris == [] ->
        {:error, :invalid_redirect_uri}

      length(uris) > @max_redirect_uris ->
        {:error, :invalid_redirect_uri}

      not Enum.all?(uris, &is_binary/1) ->
        {:error, :invalid_redirect_uri}

      true ->
        Enum.reduce_while(uris, :ok, fn uri, _acc ->
          case validate(uri) do
            :ok -> {:cont, :ok}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)
    end
  end

  def validate_list(_), do: {:error, :invalid_redirect_uri}

  defp validate(uri) when is_binary(uri) do
    trimmed = String.trim(uri)

    cond do
      trimmed == "" ->
        {:error, :invalid_redirect_uri}

      true ->
        case URI.parse(trimmed) do
          %URI{scheme: "https", host: host} when is_binary(host) and host != "" ->
            :ok

          %URI{scheme: "http", host: host} when host in @localhost_hosts ->
            :ok

          %URI{scheme: scheme} when is_binary(scheme) ->
            if denied_scheme?(scheme), do: {:error, :invalid_redirect_uri}, else: :ok

          _ ->
            {:error, :invalid_redirect_uri}
        end
    end
  end

  defp validate(_), do: {:error, :invalid_redirect_uri}

  defp denied_scheme?(scheme) when is_binary(scheme) do
    scheme in @denied_schemes
  end
end
