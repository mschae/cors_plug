defmodule CORSPlug do
  import Plug.Conn

  def defaults do
    [
      origin:      "*",
      credentials: true,
      max_age:     1728000,
      headers:     ["Authorization", "Content-Type", "Accept", "Origin",
                    "User-Agent", "DNT","Cache-Control", "X-Mx-ReqToken",
                    "Keep-Alive", "X-Requested-With", "If-Modified-Since",
                    "X-CSRF-Token"],
      expose:      [],
      methods:     ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    ]
  end

  def init(options) do
    Dict.merge defaults, options
  end

  def call(conn, options) do
    conn = put_in conn.resp_headers, conn.resp_headers ++ headers(conn, options)
    case conn.method do
      "OPTIONS" -> halt send_resp conn, 204, ""
      _method   -> conn
    end
  end

  defp headers(conn = %Plug.Conn{method: "OPTIONS"}, options) do
    headers(%{conn | method: nil}, options) ++ [
      {"access-control-max-age", "#{options[:max_age]}"},
      {"access-control-allow-headers", Enum.join(options[:headers], ",")},
      {"access-control-allow-methods", Enum.join(options[:methods], ",")}
    ]
  end

  defp headers(conn, options) do
    [
      {"access-control-allow-origin", origin(options[:origin], conn)},
      {"access-control-expose-headers", origin(options[:expose], conn)},
      {"access-control-allow-credentials", "#{options[:credentials]}"}
    ]
  end

  defp origin(:self, conn) do
    {_, host} =
      Enum.find(conn.req_headers,
                {nil, "*"},
                fn({header, _val}) -> header == "origin" end)
    host
  end

  defp origin(origin, _conn), do: origin
end
