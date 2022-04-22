defmodule RAKV.Healthcheck do
  @moduledoc """
  This module implements the healthcheck HTTP endpoint for the service.
  """
  use Plug.Router

  require Logger

  plug(:match)

  plug(:dispatch)

  get "/startupcheck" do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Dispatch Service is started")
  end

  get "/healthcheck" do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Dispatch Service is healthy")
  end

  get "/readiness" do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Dispatch Service is ready")
  end
end
