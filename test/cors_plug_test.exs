defmodule CORSPlugTest do
  use ExUnit.Case, async: true
  use Plug.Test
  import Plug.Conn, only: [get_resp_header: 2, put_req_header: 3]

  test "returns the right options for regular requests" do
    opts = CORSPlug.init([])

    conn =
      :get
      |> conn("/")
      |> CORSPlug.call(opts)

    assert ["*"] == get_resp_header(conn, "access-control-allow-origin")
  end

  test "lets me overwrite options" do
    opts = CORSPlug.init(origin: "http://example.com")

    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "http://example.com")
      |> CORSPlug.call(opts)

    assert ["http://example.com"] == get_resp_header(conn, "access-control-allow-origin")
  end

  test "halts and returns https status 204 for options requests by default" do
    opts = CORSPlug.init([])

    conn =
      :options
      |> conn("/")
      |> put_req_header("access-control-request-method", "GET")
      |> CORSPlug.call(opts)

    assert %Plug.Conn{halted: true, status: 204, state: :sent, resp_body: ""} = conn
  end

  test "lets me set options requests to not be halted" do
    opts = CORSPlug.init(send_preflight_response?: false)

    conn =
      :options
      |> conn("/")
      |> put_req_header("access-control-request-method", "GET")
      |> CORSPlug.call(opts)

    assert %Plug.Conn{halted: false, status: nil, state: :unset, resp_body: nil} = conn
  end

  test "lets me call a function to resolve origin on every request" do
    opts = CORSPlug.init(origin: fn -> "http://example.com" end)

    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "http://example.com")
      |> CORSPlug.call(opts)

    assert ["http://example.com"] == get_resp_header(conn, "access-control-allow-origin")
  end

  test "lets me call a function with conn as a arg to resolve origin on every request" do
    opts = CORSPlug.init(origin: fn _conn -> "http://example.com" end)

    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "http://example.com")
      |> CORSPlug.call(opts)

    assert ["http://example.com"] == get_resp_header(conn, "access-control-allow-origin")
  end

  test "raises when I call a function with arity > 1" do
    assert_raise RuntimeError, fn ->
      opts = CORSPlug.init(origin: fn _conn, _what? -> "http://example.com" end)

      :get
      |> conn("/")
      |> put_req_header("origin", "http://example.com")
      |> CORSPlug.call(opts)
    end
  end

  test "passes all the relevant headers on an options request" do
    opts = CORSPlug.init([])

    conn =
      :options
      |> conn("/")
      |> put_req_header("access-control-request-method", "GET")
      |> CORSPlug.call(opts)

    required_headers = [
      "access-control-allow-origin",
      "access-control-expose-headers",
      "access-control-allow-credentials",
      "access-control-max-age",
      "access-control-allow-headers",
      "access-control-allow-methods"
    ]

    for header <- required_headers do
      assert header in Enum.map(conn.resp_headers, fn {k, _} -> k end)
    end
  end

  test "does not include allow-credentials if set to false" do
    opts = CORSPlug.init(origin: "http://example.com", credentials: false)

    conn = :get |> conn("/") |> put_req_header("origin", "http://example.com")

    conn = CORSPlug.call(conn, opts)
    refute "access-control-allow-credentials" in Enum.map(conn.resp_headers, fn {k, _} -> k end)
  end

  test "returns the origin when origin is equal to origin option string" do
    opts = CORSPlug.init(origin: "http://example1.com")

    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "http://example1.com")

    conn = CORSPlug.call(conn, opts)
    assert assert ["http://example1.com"] == get_resp_header(conn, "access-control-allow-origin")
  end

  test "returns no cors header when origin is not equal to origin option string" do
    opts = CORSPlug.init(origin: "http://example1.com")

    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "http://example2.com")

    conn = CORSPlug.call(conn, opts)
    assert [] == get_resp_header(conn, "access-control-allow-origin")
  end

  test "returns the origin when origin is in origin option list" do
    opts = CORSPlug.init(origin: ["http://example1.com", "http://example2.com", "*"])

    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "http://example2.com")

    conn = CORSPlug.call(conn, opts)
    assert assert ["http://example2.com"] == get_resp_header(conn, "access-control-allow-origin")
  end

  test "returns * string when the origin * in the list" do
    opts = CORSPlug.init(origin: ["http://example1.com", "*"])

    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "http://example2.com")

    conn = CORSPlug.call(conn, opts)
    assert ["*"] == get_resp_header(conn, "access-control-allow-origin")
  end

  test "returns no CORS header when origin is not in origin option list" do
    opts = CORSPlug.init(origin: ["http://example1.com"])

    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "http://example2.com")

    conn = CORSPlug.call(conn, opts)
    assert [] == get_resp_header(conn, "access-control-allow-origin")
  end

  test "returns the origin when origin matches origin option regex" do
    opts = CORSPlug.init(origin: ~r/^example.+\.com$/)

    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "example42.com")
      |> CORSPlug.call(opts)

    assert assert ["example42.com"] == get_resp_header(conn, "access-control-allow-origin")
  end

  test "returns no CORS header when origin is null and origin option is regex" do
    opts = CORSPlug.init(origin: ~r/^example.+\.com$/)

    conn =
      :get
      |> conn("/")
      |> CORSPlug.call(opts)

    assert [] == get_resp_header(conn, "access-control-allow-origin")
  end

  test "returns no CORS header when origin is null and origin option is a list containing a regex" do
    opts = CORSPlug.init(origin: [~r/^example.+\.com$/])

    conn =
      :get
      |> conn("/")
      |> CORSPlug.call(opts)

    assert [] == get_resp_header(conn, "access-control-allow-origin")
  end

  test "returns no CORS header when origin does not match origin option regex" do
    opts = CORSPlug.init(origin: ~r/^example.+\.com$/)

    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "null-example42.com")
      |> CORSPlug.call(opts)

    assert [] == get_resp_header(conn, "access-control-allow-origin")
  end

  test "returns the request host when origin is :self" do
    opts = CORSPlug.init(origin: [:self])

    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "http://cors-plug.example")
      |> CORSPlug.call(opts)

    assert ["http://cors-plug.example"] == get_resp_header(conn, "access-control-allow-origin")
  end

  test "uses exact match origin header" do
    opts = CORSPlug.init(origin: "example1.com")

    conn =
      :get
      |> conn("/")
      |> put_req_header("x-origin", "example0.com")
      |> put_req_header("origin", "example1.com")
      |> put_req_header("original", "example2.com")
      |> CORSPlug.call(opts)

    assert ["example1.com"] == get_resp_header(conn, "access-control-allow-origin")
  end

  test "exposed headers are returned" do
    opts = CORSPlug.init(expose: ["content-range", "content-length", "accept-ranges"])

    conn =
      :options
      |> conn("/")
      |> put_req_header("access-control-request-method", "GET")
      |> CORSPlug.call(opts)

    assert get_resp_header(conn, "access-control-expose-headers") ==
             ["content-range,content-length,accept-ranges"]
  end

  test "allows all incoming headers" do
    headers = "custom-header,upgrade-insecure-requests"
    opts = CORSPlug.init(headers: ["*"])

    conn =
      :options
      |> conn("/")
      |> put_req_header("access-control-request-headers", headers)
      |> put_req_header("access-control-request-method", "GET")
      |> CORSPlug.call(opts)

    assert get_resp_header(conn, "access-control-allow-headers") ==
             ["custom-header,upgrade-insecure-requests"]
  end

  test "handles missing access-control-request-headers" do
    opts = CORSPlug.init(headers: ["*"])

    conn =
      :options
      |> conn("/")
      |> put_req_header("access-control-request-method", "GET")
      |> CORSPlug.call(opts)

    assert get_resp_header(conn, "access-control-allow-headers") ==
             [""]
  end

  test "dont include Origin in Vary response header if the Origin doesn't match" do
    opts = CORSPlug.init(origin: "http://example.com")

    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "null-example42.com")
      |> CORSPlug.call(opts)

    assert [] == get_resp_header(conn, "vary")
  end

  test "dont include Origin in Vary response header if the Access-Control-Allow-Origin is `*`" do
    opts = CORSPlug.init(origin: "*")

    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "null-example42.com")
      |> CORSPlug.call(opts)

    assert [] == get_resp_header(conn, "vary")
  end

  test "dont change Vary response header if the Access-Control-Allow-Origin is `*`" do
    opts = CORSPlug.init(origin: "*")

    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "null-example42.com")
      |> Plug.Conn.put_resp_header("vary", "User-Agent")
      |> CORSPlug.call(opts)

    assert ["User-Agent"] == get_resp_header(conn, "vary")
  end

  test "prepend Origin in Vary response header if the Origin matches and Vary header was set" do
    opts = CORSPlug.init(origin: "http://example.com")

    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "http://example.com")
      |> Plug.Conn.put_resp_header("vary", "User-Agent")
      |> CORSPlug.call(opts)

    assert ["Origin, User-Agent"] == get_resp_header(conn, "vary")
  end

  test "allowed methods in options are properly returned" do
    opts = CORSPlug.init(methods: ~w[GET POST])

    conn =
      :options
      |> conn("/")
      |> put_req_header("access-control-request-method", "GET")
      |> CORSPlug.call(opts)

    allowed_methods = get_resp_header(conn, "access-control-allow-methods")
    assert allowed_methods == ["GET,POST"]
  end

  test "default allowed methods are properly returned" do
    opts = CORSPlug.init([])

    conn =
      :options
      |> conn("/")
      |> put_req_header("access-control-request-method", "GET")
      |> CORSPlug.call(opts)

    allowed_methods = get_resp_header(conn, "access-control-allow-methods")
    assert allowed_methods == ["GET,POST,PUT,PATCH,DELETE,OPTIONS"]
  end

  test "expose headers in options are properly returned" do
    opts = CORSPlug.init(expose: ["X-My-Custom-Header", "X-Another-Custom-Header"])

    conn =
      :get
      |> conn("/")
      |> CORSPlug.call(opts)

    expose_headers = get_resp_header(conn, "access-control-expose-headers")
    assert expose_headers == ["X-My-Custom-Header,X-Another-Custom-Header"]
  end

  test "allows to be configured via app config" do
    Application.put_env(:cors_plug, :headers, ["X-App-Config-Header"])

    opts = CORSPlug.init([])

    conn =
      :options
      |> conn("/")
      |> put_req_header("access-control-request-method", "GET")
      |> CORSPlug.call(opts)

    expose_headers = get_resp_header(conn, "access-control-allow-headers")
    assert expose_headers == ["X-App-Config-Header"]
  end

  test "init headers override app headers" do
    Application.put_env(:cors_plug, :headers, ["X-App-Config-Header"])

    opts = CORSPlug.init(headers: ["X-Init-Config-Header"])

    conn =
      :options
      |> conn("/")
      |> put_req_header("access-control-request-method", "GET")
      |> CORSPlug.call(opts)

    expose_headers = get_resp_header(conn, "access-control-allow-headers")
    assert expose_headers == ["X-Init-Config-Header"]
  end

  test "allows to mix regex and string in origin configuration" do
    opts = CORSPlug.init(origin: ["http://string.com", ~r/^regex.+\.com$/])

    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "regex42.com")
      |> CORSPlug.call(opts)

    assert ["regex42.com"] == get_resp_header(conn, "access-control-allow-origin")

    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "http://string.com")
      |> CORSPlug.call(opts)

    assert ["http://string.com"] == get_resp_header(conn, "access-control-allow-origin")
  end

  test "don't process non-cors preflight requests" do
    opts = CORSPlug.init(origin: "http://example.com")

    conn =
      :options
      |> conn("/")
      |> put_req_header("origin", "http://example.com")
      |> CORSPlug.call(opts)

    assert [] == get_resp_header(conn, "access-control-allow-origin")
  end
end
