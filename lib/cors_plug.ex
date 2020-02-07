defmodule CORSPlug do
  import Plug.Conn

  def defaults do
    [
      origin: "*",
      credentials: true,
      max_age: 1_728_000,
      headers: [
        "Authorization",
        "Content-Type",
        "Accept",
        "Origin",
        "User-Agent",
        "DNT",
        "Cache-Control",
        "X-Mx-ReqToken",
        "Keep-Alive",
        "X-Requested-With",
        "If-Modified-Since",
        "X-CSRF-Token"
      ],
      expose: [],
      methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
      send_preflight_response?: true
    ]
  end

  @doc false
  def call(conn, options) do
    conn = merge_resp_headers(conn, headers(conn, options))

    case {options[:send_preflight_response?], conn.method} do
      {true, "OPTIONS"} -> conn |> send_resp(204, "") |> halt()
      {_, _method} -> conn
    end
  end

  @doc false
  def init(options) do
    options
    |> prepare_cfg(Application.get_all_env(:cors_plug))
    |> Keyword.update!(:expose, &Enum.join(&1, ","))
    |> Keyword.update!(:methods, &Enum.join(&1, ","))
  end

  defp prepare_cfg(options, env) do
    defaults()
    |> Keyword.merge(env)
    |> Keyword.merge(options)
  end

  # headers specific to OPTIONS request
  defp headers(conn = %Plug.Conn{method: "OPTIONS"}, options) do
    headers(%{conn | method: nil}, options) ++
      [
        {"access-control-max-age", "#{options[:max_age]}"},
        {"access-control-allow-headers", allowed_headers(options[:headers], conn)},
        {"access-control-allow-methods", options[:methods]}
      ]
  end

  # universal headers
  defp headers(conn, options) do
    allowed_origin = origin(options[:origin], conn)
    vary_header = vary_header(allowed_origin, get_resp_header(conn, "vary"))

    vary_header ++ cors_headers(allowed_origin, options)
  end

  # When the origin doesnt match, dont send CORS headers
  defp cors_headers(nil, _options) do
    []
  end

  defp cors_headers(allowed_origin, options) do
    [
      {"access-control-allow-origin", allowed_origin},
      {"access-control-expose-headers", options[:expose]},
      {"access-control-allow-credentials", "#{options[:credentials]}"}
    ]
  end

  # Allow all requested headers
  defp allowed_headers(["*"], conn) do
    case get_req_header(conn, "access-control-request-headers") do
      [first | _tail] -> first
      _ -> ""
    end
  end

  defp allowed_headers(key, _conn) do
    Enum.join(key, ",")
  end

  # return origin if it matches regex, otherwise nil
  defp origin(%Regex{} = regex, conn) do
    req_origin = conn |> request_origin() |> to_string()

    if origins_match?(req_origin, regex), do: req_origin, else: nil
  end

  # get value if origin is a function
  defp origin(fun, conn) when is_function(fun) do
    case Function.info(fun, :arity) do
      {:arity, 0} ->
        origin(fun.(), conn)

      {:arity, 1} ->
        origin(fun.(conn), conn)

      {:arity, arity} ->
        raise """
        Passing a function with arity #{arity} is not supported. Please use
        one with arity 0 or 1 (in which case it will be passed the `conn`).
        """
    end
  end

  # normalize non-list to list
  defp origin(key, conn) when not is_list(key) do
    key
    |> List.wrap()
    |> origin(conn)
  end

  # whitelist internal requests
  defp origin([:self], conn) do
    request_origin(conn) || "*"
  end

  # return "*" if origin list is ["*"]
  defp origin(["*"], _conn) do
    "*"
  end

  defp origin(origins, conn) when is_list(origins) do
    req_origin = conn |> request_origin() |> to_string()

    cond do
      origin_in_list?(req_origin, origins) -> req_origin
      "*" in origins -> "*"
      true -> nil
    end
  end

  def origin_in_list?(req_origin, origins) do
    Enum.any?(origins, &origins_match?(req_origin, &1))
  end

  def origins_match?(req_origin, origin) when is_binary(origin) do
    req_origin == origin
  end

  def origins_match?(req_origin, %Regex{} = origin) do
    req_origin =~ origin
  end

  defp request_origin(%Plug.Conn{req_headers: headers}) do
    Enum.find_value(headers, fn {k, v} -> k =~ ~r/^origin$/i && v end)
  end

  # Set the Vary response header
  # see: https://www.w3.org/TR/cors/#resource-implementation
  defp vary_header("*", _headers), do: []
  defp vary_header(nil, _headers), do: []
  defp vary_header(_allowed_origin, []), do: [{"vary", "Origin"}]

  defp vary_header(_allowed_origin, headers) do
    vary = Enum.join(["Origin" | headers], ", ")

    [{"vary", vary}]
  end
end
