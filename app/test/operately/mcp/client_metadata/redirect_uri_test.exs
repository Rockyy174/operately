defmodule Operately.Mcp.ClientMetadata.RedirectUriTest do
  use ExUnit.Case, async: true

  alias Operately.Mcp.ClientMetadata.RedirectUri

  test "accepts https redirect uris" do
    assert RedirectUri.valid?("https://client.example.com/callback")
  end

  test "accepts localhost http redirect uris" do
    assert RedirectUri.valid?("http://localhost:4567/callback")
    assert RedirectUri.valid?("http://127.0.0.1/callback")
  end

  test "accepts cursor callback redirect uris" do
    assert RedirectUri.valid?("cursor://anysphere.cursor-mcp/oauth/callback")
  end

  test "accepts other custom app scheme redirect uris" do
    assert RedirectUri.valid?("vscode://my-extension/oauth/callback")
  end

  test "rejects dangerous custom scheme redirect uris" do
    refute RedirectUri.valid?("javascript:alert(1)")
    refute RedirectUri.valid?("data:text/html,hello")
    refute RedirectUri.valid?("file:///etc/passwd")
  end

  test "rejects remote http redirect uris" do
    refute RedirectUri.valid?("http://evil.example.com/callback")
  end

  test "rejects empty redirect uris" do
    assert {:error, :invalid_redirect_uri} = RedirectUri.validate_list([])
    refute RedirectUri.valid?("")
  end

  test "rejects redirect uri lists over the maximum" do
    uris = for index <- 1..11, do: "https://client#{index}.example.com/callback"

    assert {:error, :invalid_redirect_uri} = RedirectUri.validate_list(uris)
  end
end
