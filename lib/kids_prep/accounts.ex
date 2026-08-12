defmodule KidsPrep.Accounts do
  @moduledoc false

  @users %{
    "mihrimah" => %{
      "username" => "mihrimah",
      "password_env" => "KIDS_PREP_MIHRIMAH_PASSWORD",
      "display_name" => "Mihrimah",
      "role" => "learner",
      "child_slug" => "mihrimah"
    },
    "mustafa" => %{
      "username" => "mustafa",
      "password_env" => "KIDS_PREP_MUSTAFA_PASSWORD",
      "display_name" => "Mustafa",
      "role" => "learner",
      "child_slug" => "mustafa"
    },
    "admin" => %{
      "username" => "admin",
      "password_env" => "KIDS_PREP_ADMIN_PASSWORD",
      "display_name" => "Admin",
      "role" => "admin",
      "child_slug" => nil
    }
  }

  def authenticate(username, password) do
    username = username |> to_string() |> String.trim() |> String.downcase()
    password = to_string(password)

    with %{"password_env" => password_env} = user <- Map.get(@users, username),
         expected when is_binary(expected) and expected != "" <- System.get_env(password_env),
         true <- secure_equal?(password, expected) do
      {:ok, Map.delete(user, "password_env")}
    else
      _ -> :error
    end
  end

  def allowed_child?(%{"role" => "admin"}, _child_slug), do: true
  def allowed_child?(%{"child_slug" => child_slug}, child_slug), do: true
  def allowed_child?(_, _), do: false

  def admin?(%{"role" => "admin"}), do: true
  def admin?(_user), do: false

  defp secure_equal?(left, right) when byte_size(left) == byte_size(right) do
    Plug.Crypto.secure_compare(left, right)
  end

  defp secure_equal?(_, _), do: false
end
