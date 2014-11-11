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

  test "origin :self returns the request host" do
    opts = CORSPlug.init(origin: :self)
    conn = conn(:get, "/", nil)

    conn = CORSPlug.call(conn, opts)

    assert Enum.member? conn.resp_headers,
                        {"access-control-allow-origin", "www.example.com"}
  end
end
