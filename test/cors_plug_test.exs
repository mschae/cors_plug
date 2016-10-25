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
    conn = conn(:get, "/") |> put_req_header("origin", "http://example.com")

    conn = CORSPlug.call(conn, opts)

    assert ["http://example.com"] ==
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

  test "returns the origin when it is valid" do
    opts = CORSPlug.init(origin: ["example1.com", "example2.com"])
    conn = conn(:get, "/") |> put_req_header("origin", "http://example1.com")

    conn = CORSPlug.call(conn, opts)
    assert assert ["http://example1.com"] ==
           get_resp_header(conn, "access-control-allow-origin")
  end

  test "returns the origin even with other port" do
    opts = CORSPlug.init(origin: ["example1.com", "example2.com"])
    conn = conn(:get, "/") |> put_req_header("origin", "http://example1.com:8000")

    conn = CORSPlug.call(conn, opts)
    assert assert ["http://example1.com:8000"] ==
           get_resp_header(conn, "access-control-allow-origin")
  end

  test "returns the origin when header is uppercase (Origin)" do
    opts = CORSPlug.init(origin: ["example1.com", "example2.com"])
    conn = conn(:get, "/") |> Map.put(:req_headers, [{"Origin", "http://example1.com"}])

    conn = CORSPlug.call(conn, opts)
    assert assert ["http://example1.com"] ==
           get_resp_header(conn, "access-control-allow-origin")
  end

  test "returns null string when the origin is invalid" do
    opts = CORSPlug.init(origin: ["example1.com"])
    conn = conn(:get, "/") |> put_req_header("origin", "http://example2.com")

    conn = CORSPlug.call(conn, opts)
    assert ["null"] == get_resp_header conn, "access-control-allow-origin"
  end

  test "returns the request host when origin is :self" do
    opts = CORSPlug.init(origin: [:self])
    conn = conn(:get, "/") |> put_req_header("origin", "http://cors-plug.example")

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
    conn = conn(:options, "/") |> put_req_header("access-control-request-headers", "custom-header,upgrade-insecure-requests")

    conn = CORSPlug.call(conn, opts)

    assert get_resp_header(conn, "access-control-allow-headers") ==
      ["custom-header,upgrade-insecure-requests"]
  end
end
