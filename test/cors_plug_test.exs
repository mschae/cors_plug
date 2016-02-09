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

    required_headers = [
      "access-control-allow-origin",
      "access-control-expose-headers",
      "access-control-allow-credentials",
      "access-control-max-age",
      "access-control-allow-headers",
      "access-control-allow-methods"
    ]

    for header <- required_headers do
      assert header in Keyword.keys(conn.resp_headers)
    end
  end

  test "origin :self returns the request host" do
    opts = CORSPlug.init(origin: :self)
    conn = conn(:get, "/", nil,
                headers: [{"origin", "http://cors-plug.example"}])

    conn = CORSPlug.call(conn, opts)

    assert Enum.member? conn.resp_headers,
                        {"access-control-allow-origin", "http://cors-plug.example"}
  end

  test "exposed headers are returned" do
    opts = CORSPlug.init(expose: ["content-range", "content-length", "accept-ranges"])
    conn = conn(:options, "/")

    conn = CORSPlug.call(conn, opts)

    assert get_resp_header(conn, "access-control-expose-headers") == ["content-range,content-length,accept-ranges"]
  end
end
