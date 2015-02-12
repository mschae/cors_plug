defmodule CORSPlugTest do
  use ExUnit.Case
  use Plug.Test


  test "returns the right options for regular requests" do
    opts = CORSPlug.init([])
    conn = conn(:get, "/")

    conn = CORSPlug.call(conn, opts)

    assert Enum.member? conn.resp_headers, {"access-control-allow-origin", "*"}
  end

  test "lets me overwrite options" do
    opts = CORSPlug.init(origin: "example.com")
    conn = conn(:get, "/")

    conn = CORSPlug.call(conn, opts)

    assert Enum.member? conn.resp_headers,
                        {"access-control-allow-origin", "example.com"}
  end

  test "passes all the relevant headers on an options request" do
    opts = CORSPlug.init([])
    conn = conn(:options, "/")

    conn = CORSPlug.call(conn, opts)

    headers =
      conn.resp_headers
      |> Enum.map(fn({key, _value}) -> key end)

    assert headers == [
      "access-control-allow-origin",
      "access-control-allow-credentials",
      "access-control-max-age",
      "access-control-allow-headers",
      "access-control-allow-methods"
    ]
  end

  test "origin :self returns the request host" do
    opts = CORSPlug.init(origin: :self)
    conn = conn(:get, "/", nil,
                headers: [{"origin", "http://cors-plug.example"}])

    conn = CORSPlug.call(conn, opts)

    assert Enum.member? conn.resp_headers,
                        {"access-control-allow-origin", "http://cors-plug.example"}
  end
end
