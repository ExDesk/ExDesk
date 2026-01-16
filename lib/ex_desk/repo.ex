defmodule ExDesk.Repo do
  use Ecto.Repo,
    otp_app: :ex_desk,
    adapter: Ecto.Adapters.Postgres
end
