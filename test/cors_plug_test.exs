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
    opts = CORSPlug.init(origins: ["example.com"])
    conn = conn(:get, "/", nil,
                headers: [{"origin", "example.com"}])

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

  test "returns the origin when it is valid" do
    opts = CORSPlug.init(origins: ["example1.com", "example2.com"])
    conn = conn(:get, "/", nil,
                headers: [{"origin", "example1.com"}])

    conn = CORSPlug.call(conn, opts)
    assert Enum.member? conn.resp_headers, {"access-control-allow-origin", "example1.com"}
  end

  test "returns nil when the origin is invalid" do
    opts = CORSPlug.init(origins: ["example1.com"])
    conn = conn(:get, "/", nil,
                headers: [{"origin", "example2.com"}])

    conn = CORSPlug.call(conn, opts)
    assert Enum.member? conn.resp_headers, {"access-control-allow-origin", nil}
  end

  test "returns the request host when origin is :self" do
    opts = CORSPlug.init(origins: [:self])
    conn = conn(:get, "/", nil,
                headers: [{"origin", "http://cors-plug.example"}])

    conn = CORSPlug.call(conn, opts)

    assert Enum.member? conn.resp_headers,
                        {"access-control-allow-origin", "http://cors-plug.example"}
  end
end
