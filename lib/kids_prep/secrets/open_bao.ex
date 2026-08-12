defmodule KidsPrep.Secrets.OpenBao do
  @moduledoc false

  @token_cache_key {__MODULE__, :approle_token}

  def read_notion_token do
    direct_notion_token() || oauth_access_token()
  end

  def read_notion_oauth_config do
    read_app_secret("notion/oauth")
  end

  def read_notion_config do
    read_app_secret("notion/config")
  end

  def read_login_users do
    read_app_secret("login/users")
  end

  def read_notion_oauth_tokens do
    read_app_secret("notion/tokens")
  end

  def write_notion_oauth_tokens(attrs) when is_map(attrs) do
    write_app_secret("notion/tokens", attrs)
  end

  def read_app_secret(relative_path) do
    with {:ok, addr} <- first_env(["OPENBAO_ADDR", "BAO_ADDR", "VAULT_ADDR"]),
         {:ok, token} <- client_token(addr) do
      read_secret(addr, token, app_path(relative_path))
    end
  end

  def write_app_secret(relative_path, attrs) when is_map(attrs) do
    with {:ok, addr} <- first_env(["OPENBAO_ADDR", "BAO_ADDR", "VAULT_ADDR"]),
         {:ok, token} <- client_token(addr) do
      write_secret(addr, token, app_path(relative_path), attrs)
    end
  end

  defp client_token(addr) do
    case first_env(["OPENBAO_TOKEN", "BAO_TOKEN", "VAULT_TOKEN"]) do
      {:ok, token} -> {:ok, token}
      _ -> approle_token(addr)
    end
  end

  defp approle_token(addr) do
    now = System.system_time(:second)

    case :persistent_term.get(@token_cache_key, nil) do
      %{token: token, expires_at: expires_at} when expires_at > now + 30 ->
        {:ok, token}

      _ ->
        login_with_approle(addr, now)
    end
  end

  defp login_with_approle(addr, now) do
    with {:ok, role_id} <- first_env(["OPENBAO_ROLE_ID", "BAO_ROLE_ID", "VAULT_ROLE_ID"]),
         {:ok, secret_id} <- first_env(["OPENBAO_SECRET_ID", "BAO_SECRET_ID", "VAULT_SECRET_ID"]) do
      auth_path = System.get_env("OPENBAO_APPROLE_AUTH_PATH") || "approle"
      url = "#{String.trim_trailing(addr, "/")}/v1/auth/#{String.trim(auth_path, "/")}/login"

      Req.post(url, json: %{role_id: role_id, secret_id: secret_id})
      |> case do
        {:ok, %{status: status, body: %{"auth" => %{"client_token" => token} = auth}}}
        when status in 200..299 ->
          lease_duration = Map.get(auth, "lease_duration", 300)

          :persistent_term.put(@token_cache_key, %{token: token, expires_at: now + lease_duration})

          {:ok, token}

        _ ->
          {:error, :openbao_approle_login_failed}
      end
    end
  end

  defp read_secret(addr, token, path) do
    mount = System.get_env("OPENBAO_KV_MOUNT") || "secret"
    url = "#{String.trim_trailing(addr, "/")}/v1/#{mount}/data/#{path}"

    Req.get(url, headers: [{"x-vault-token", token}])
    |> case do
      {:ok, %{status: status, body: %{"data" => %{"data" => data}}}} when status in 200..299 ->
        {:ok, data}

      _ ->
        {:error, :openbao_read_failed}
    end
  end

  defp write_secret(addr, token, path, attrs) do
    mount = System.get_env("OPENBAO_KV_MOUNT") || "secret"
    url = "#{String.trim_trailing(addr, "/")}/v1/#{mount}/data/#{path}"

    Req.post(url, headers: [{"x-vault-token", token}], json: %{data: attrs})
    |> case do
      {:ok, %{status: status}} when status in 200..299 -> :ok
      _ -> {:error, :openbao_write_failed}
    end
  end

  defp direct_notion_token do
    path = System.get_env("OPENBAO_NOTION_SECRET_PATH") || "kids-prep/notion"
    field = System.get_env("OPENBAO_NOTION_TOKEN_FIELD") || "notion_token"

    case read_secret_from_path(path) do
      {:ok, data} -> data[field]
      _ -> nil
    end
  end

  defp oauth_access_token do
    case read_notion_oauth_tokens() do
      {:ok, data} -> data["access_token"]
      _ -> nil
    end
  end

  defp read_secret_from_path(path) do
    with {:ok, addr} <- first_env(["OPENBAO_ADDR", "BAO_ADDR", "VAULT_ADDR"]),
         {:ok, token} <- client_token(addr) do
      read_secret(addr, token, path)
    end
  end

  defp app_path(relative_path) do
    base = System.get_env("OPENBAO_APP_SECRET_PATH") || "coolify/kids-prep"

    [base, relative_path]
    |> Enum.map(&String.trim(&1, "/"))
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("/")
  end

  defp first_env(names) do
    names
    |> Enum.find_value(&present_env/1)
    |> case do
      nil -> {:error, {:missing_env, names}}
      value -> {:ok, value}
    end
  end

  defp present_env(name) do
    case System.get_env(name) do
      value when value in [nil, ""] -> nil
      value -> value
    end
  end
end
