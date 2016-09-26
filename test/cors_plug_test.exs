defmodule CORSPlugTest do
  use ExUnit.Case
  use Plug.Test
  import Plug.Conn, only: [get_resp_header: 2, put_req_header: 3]

  test "returns the right options for regular requests" do
    opts = CORSPlug.init([])
    conn = conn(:get, "/")

    conn = CORSPlug.call(conn, opts)

    assert ["*"] == get_resp_header conn, "access-control-allow-origin"
  end

  test "lets me overwrite options" do
    opts = CORSPlug.init(origin: "example.com")
    conn = conn(:get, "/")
    |> put_req_header("origin", "example.com")

    conn = CORSPlug.call(conn, opts)

    assert ["example.com"] ==
           get_resp_header(conn, "access-control-allow-origin")
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

  test "returns the origin when equal to origin string" do
    opts = CORSPlug.init(origin: "example1.com")
    conn = conn(:get, "/")
    |> put_req_header("origin", "example1.com")

    conn = CORSPlug.call(conn, opts)
    assert assert ["example1.com"] ==
           get_resp_header(conn, "access-control-allow-origin")
  end

  test "returns null string when not equal to origin string" do
    opts = CORSPlug.init(origin: "example1.com")
    conn = conn(:get, "/")
    |> put_req_header("origin", "example2.com")

    conn = CORSPlug.call(conn, opts)
    assert ["null"] == get_resp_header conn, "access-control-allow-origin"
  end

  test "returns the origin when in origin list" do
    opts = CORSPlug.init(origin: ["example1.com", "example2.com"])
    conn = conn(:get, "/")
    |> put_req_header("origin", "example2.com")

    conn = CORSPlug.call(conn, opts)
    assert assert ["example2.com"] ==
           get_resp_header(conn, "access-control-allow-origin")
  end

  test "returns null string when not in origin list" do
    opts = CORSPlug.init(origin: ["example1.com"])
    conn = conn(:get, "/")
    |> put_req_header("origin", "example2.com")

    conn = CORSPlug.call(conn, opts)
    assert ["null"] == get_resp_header conn, "access-control-allow-origin"
  end

  test "returns the origin when matches origin regex" do
    opts = CORSPlug.init(origin: ~r/^example.+\.com$/)
    conn = conn(:get, "/")
    |> put_req_header("origin", "example42.com")

    conn = CORSPlug.call(conn, opts)
    assert assert ["example42.com"] ==
           get_resp_header(conn, "access-control-allow-origin")
  end

  test "returns null string when does not match origin regex" do
    opts = CORSPlug.init(origin: ~r/^example.+\.com$/)
    conn = conn(:get, "/")
    |> put_req_header("origin", "null-example42.com")

    conn = CORSPlug.call(conn, opts)
    assert ["null"] == get_resp_header conn, "access-control-allow-origin"
  end

  test "returns the request host when origin is :self" do
    opts = CORSPlug.init(origin: [:self])
    conn = conn(:get, "/")
    |> put_req_header("origin", "http://cors-plug.example")

    conn = CORSPlug.call(conn, opts)

    assert ["http://cors-plug.example"] ==
           get_resp_header(conn, "access-control-allow-origin")
  end

  test "exposed headers are returned" do
    opts = CORSPlug.init(expose: ["content-range", "content-length", "accept-ranges"])
    conn = conn(:options, "/")

    conn = CORSPlug.call(conn, opts)

    assert get_resp_header(conn, "access-control-expose-headers") ==
      ["content-range,content-length,accept-ranges"]
  end

  test "allows all incoming headers" do
    opts = CORSPlug.init(headers: ["*"])
    conn = conn(:options, "/")
    |> put_req_header("access-control-request-headers", "custom-header,upgrade-insecure-requests")

    conn = CORSPlug.call(conn, opts)

    assert get_resp_header(conn, "access-control-allow-headers") ==
      ["custom-header,upgrade-insecure-requests"]
  end
end
