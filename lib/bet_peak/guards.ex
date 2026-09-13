defmodule BetPeak.Guards do
  def require_super_admin(status, user) do
    cond do
      status == true and user.role == :admin and user.is_superuser == true ->
        :authorized

      status == false and user.role == :admin ->
        :authorized

      true ->
        :unauthorized
    end
  end
end
