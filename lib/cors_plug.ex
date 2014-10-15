defmodule CORSPlug do
  import Plug.Conn

  def init(options) do
    Dict.merge [
      origin:      "*",
      credentials: true,
      max_age:     1728000,
      headers:     ["Authorization", "Content-Type", "Accept", "Origin",
                    "User-Agent", "DNT","Cache-Control", "X-Mx-ReqToken",
                    "Keep-Alive", "X-Requested-With", "If-Modified-Since",
                    "X-CSRF-Token"],
      methods:     ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    ], options
  end

  def call(conn, options) do
    conn = %{conn | resp_headers: headers(conn.method, options)}
    case conn.method do
      "OPTIONS" -> halt send_resp conn, 204, ""
      _method   -> conn
    end
  end

  defp headers("OPTIONS", options) do
    headers("", options) ++ [
      {"access-control-max-age", "#{options[:max_age]}"},
      {"access-control-allow-headers", Enum.join(options[:headers], ",")},
      {"access-control-allow-methods", Enum.join(options[:methods], ",")}
    ]
  end

  defp headers(_method, options) do
    [
      {"access-control-allow-origin", options[:origin]},
      {"access-control-allow-credentials", "#{options[:credentials]}"}
    ]
  end
end
