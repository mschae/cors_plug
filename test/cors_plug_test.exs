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
    conn = :get
      |> conn("/")
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

  test "returns the origin when origin is equal to origin option string" do
    opts = CORSPlug.init(origin: "example1.com")
    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "example1.com")

    conn = CORSPlug.call(conn, opts)
    assert assert ["example1.com"] ==
           get_resp_header(conn, "access-control-allow-origin")
  end

  test "returns null string when origin is not equal to origin option string" do
    opts = CORSPlug.init(origin: "example1.com")
    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "example2.com")

    conn = CORSPlug.call(conn, opts)
    assert ["null"] == get_resp_header conn, "access-control-allow-origin"
  end

  test "returns the origin when origin is in origin option list" do
    opts = CORSPlug.init(origin: ["example1.com", "example2.com"])
    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "example2.com")

    conn = CORSPlug.call(conn, opts)
    assert assert ["example2.com"] ==
           get_resp_header(conn, "access-control-allow-origin")
  end

  test "returns null string when origin is not in origin option list" do
    opts = CORSPlug.init(origin: ["example1.com"])
    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "example2.com")

    conn = CORSPlug.call(conn, opts)
    assert ["null"] == get_resp_header conn, "access-control-allow-origin"
  end

  test "returns the origin when origin matches origin option regex" do
    opts = CORSPlug.init(origin: ~r/^example.+\.com$/)
    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "example42.com")

    conn = CORSPlug.call(conn, opts)
    assert assert ["example42.com"] ==
           get_resp_header(conn, "access-control-allow-origin")
  end

  test "returns null string when origin is null and origin option is regex" do
    opts = CORSPlug.init(origin: ~r/^example.+\.com$/)
    conn = conn(:get, "/")

    conn = CORSPlug.call(conn, opts)
    assert ["null"] == get_resp_header conn, "access-control-allow-origin"
  end

  test "returns null string when origin does not match origin option regex" do
    opts = CORSPlug.init(origin: ~r/^example.+\.com$/)
    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "null-example42.com")

    conn = CORSPlug.call(conn, opts)
    assert ["null"] == get_resp_header conn, "access-control-allow-origin"
  end

  test "retrieves origin from environment when passed {:system, var} tuple" do
    on_exit(fn -> System.delete_env("SOME_ENV_VAR") end)

    opts = CORSPlug.init(origin: {:system, "SOME_ENV_VAR"})
    assert nil == opts[:origin]

    System.put_env("SOME_ENV_VAR", "http://example17.com")

    opts = CORSPlug.init(origin: {:system, "SOME_ENV_VAR"})
    assert "http://example17.com" == opts[:origin]
  end

  test "retrieves origin when passed {Module, function} tuple" do
    opts = CORSPlug.init(origin: {DummyModule, :example})

    assert "http://example.com" == opts[:origin]
  end

  test "retrieves origin when passed {Module, function, args} tuple" do
    opts = CORSPlug.init(origin: {DummyModule, :example, [17]})

    assert "http://example17.com" == opts[:origin]
  end

  test "returns max age when configured as a number" do
    opts = CORSPlug.init(max_age: 42)

    assert 42 == opts[:max_age]
  end

  test "returns max age when configured as a string" do
    opts = CORSPlug.init(max_age: "42")

    assert 42 == opts[:max_age]
  end

  test "returns the request host when origin is :self" do
    opts = CORSPlug.init(origin: [:self])
    conn =
      :get
      |> conn("/")
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
    conn =
      :options
      |> conn("/")
      |> put_req_header(
        "access-control-request-headers",
        "custom-header,upgrade-insecure-requests")

    conn = CORSPlug.call(conn, opts)

    assert get_resp_header(conn, "access-control-allow-headers") ==
      ["custom-header,upgrade-insecure-requests"]
  end
end
