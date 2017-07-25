defmodule Origins do
  def get_origin, do: "example.com"
  def get_list_of_origins, do: ["badexample.org", "goodexample.com"]
  def get_recursive_origin, do: {Origins, :get_origin}
end

defmodule CORSPlugTest do
  use ExUnit.Case
  use Plug.Test
  import Plug.Conn, only: [assign: 3, get_resp_header: 2, put_req_header: 3]

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
    opts = CORSPlug.init(origin: ["example1.com", "example2.com", "*"])
    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "example2.com")

    conn = CORSPlug.call(conn, opts)
    assert assert ["example2.com"] ==
           get_resp_header(conn, "access-control-allow-origin")
  end

  test "returns * string when the origin * in the list" do
    opts = CORSPlug.init(origin: ["example1.com", "*"])
    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "example2.com")

    conn = CORSPlug.call(conn, opts)
    assert ["*"] == get_resp_header conn, "access-control-allow-origin"
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

  test "uses exact match origin header" do
    opts = CORSPlug.init(origin: "example1.com")
    conn =
      :get
      |> conn("/")
      |> put_req_header("x-origin", "example0.com")
      |> put_req_header("origin", "example1.com")
      |> put_req_header("original", "example2.com")

    conn = CORSPlug.call(conn, opts)

    assert ["example1.com"] ==
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

  test "include Origin in Vary response header if the Access-Control-Allow-Origin is not `*`" do
    opts = CORSPlug.init(origin: "http://example.com")
    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "null-example42.com")

    conn = CORSPlug.call(conn, opts)
    assert ["Origin"] == get_resp_header conn, "vary"
  end

  test "dont include Origin in Vary response header if the Access-Control-Allow-Origin is `*`" do
    opts = CORSPlug.init(origin: "*")
    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "null-example42.com")

    conn = CORSPlug.call(conn, opts)
    assert [] == get_resp_header conn, "vary"
  end

  test "dont change Vary response header if the Access-Control-Allow-Origin is `*`" do
    opts = CORSPlug.init(origin: "*")
    conn =
      :get
      |> conn("/")
      |> put_req_header("origin", "null-example42.com")
      |> Plug.Conn.put_resp_header("vary", "User-Agent")

    conn = CORSPlug.call(conn, opts)
    assert ["User-Agent"] == get_resp_header conn, "vary"
  end

  test "allowed methods in options are properly returned" do
    opts = CORSPlug.init(methods: ~w[GET POST])
    conn = conn(:options, "/")
    conn = CORSPlug.call(conn, opts)

    allowed_methods = get_resp_header(conn, "access-control-allow-methods")
    assert allowed_methods == ["GET,POST"]
  end

  test "default allowed methods are properly returned" do
    opts = CORSPlug.init([])
    conn = conn(:options, "/")
    conn = CORSPlug.call(conn, opts)

    allowed_methods = get_resp_header(conn, "access-control-allow-methods")
    assert allowed_methods == ["GET,POST,PUT,PATCH,DELETE,OPTIONS"]
  end

  test "expose headers in options are properly returned" do
    opts = CORSPlug.init(expose: ["X-My-Custom-Header", "X-Another-Custom-Header"])
    conn = conn(:get, "/")
    conn = CORSPlug.call(conn, opts)

    expose_headers = get_resp_header(conn, "access-control-expose-headers")
    assert expose_headers == ["X-My-Custom-Header,X-Another-Custom-Header"]
  end

  test "allows to be configured via app config" do
    Application.put_env :cors_plug, :headers, ["X-App-Config-Header"]

    opts = CORSPlug.init([])
    conn = conn(:options, "/")
    conn = CORSPlug.call(conn, opts)

    expose_headers = get_resp_header(conn, "access-control-allow-headers")
    assert expose_headers == ["X-App-Config-Header"]
  end

  test "init headers override app headers" do
    Application.put_env :cors_plug, :headers, ["X-App-Config-Header"]

    opts = CORSPlug.init(headers: ["X-Init-Config-Header"])
    conn = conn(:options, "/")
    conn = CORSPlug.call(conn, opts)

    expose_headers = get_resp_header(conn, "access-control-allow-headers")
    assert expose_headers == ["X-Init-Config-Header"]
  end

  test "takes origin from conn assigns ignoring provided" do
    opts = CORSPlug.init(origin: "badexample.org")
    conn = :get
      |> conn("/")
      |> put_req_header("origin", "example.com")
      |> assign(:origin, ["goodexample.com", "example.com"])

    conn = CORSPlug.call(conn, opts)

    assert ["example.com"] ==
           get_resp_header(conn, "access-control-allow-origin")

  end

  test "takes single origin from external module" do
    opts = CORSPlug.init(origin: {Origins, :get_origin})
    conn = :get
      |> conn("/")
      |> put_req_header("origin", "example.com")

    conn = CORSPlug.call(conn, opts)

    assert ["example.com"] ==
           get_resp_header(conn, "access-control-allow-origin")
  end

  test "takes list of origins from external module" do
    opts = CORSPlug.init(origin: {Origins, :get_list_of_origins})
    conn = :get
      |> conn("/")
      |> put_req_header("origin", "goodexample.com")

    conn = CORSPlug.call(conn, opts)

    assert ["goodexample.com"] ==
           get_resp_header(conn, "access-control-allow-origin")
  end

  test "takes {mod, fun} from external module for recursive call" do
    opts = CORSPlug.init(origin: {Origins, :get_recursive_origin})
    conn = :get
      |> conn("/")
      |> put_req_header("origin", "example.com")

    conn = CORSPlug.call(conn, opts)

    assert ["example.com"] ==
           get_resp_header(conn, "access-control-allow-origin")
  end

end
