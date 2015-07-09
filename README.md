CorsPlug
========
[![Build Status](https://travis-ci.org/mschae/cors_plug.svg)](https://travis-ci.org/mschae/cors_plug)

An [Elixir Plug](http://github.com/elixir-lang/plug) to add [CORS](http://www.w3.org/TR/cors/).

## Usage

1. Add this plug to your `mix.exs` dependencies:

```elixir
def deps do
  # ...
  {:cors_plug, "~> 0.1.1"},
  #...
end
```

Use it in a phoenix pipeline (or wherever):

```elixir
pipeline :api do
  plug CORSPlug
  super
end
```


## Configuration

This plug will return the following headers:

On preflight (`OPTIONS`) requests:

* Access-Control-Allow-Origin
* Access-Control-Allow-Credentials
* Access-Control-Max-Age
* Access-Control-Allow-Headers
* Access-Control-Allow-Methods

On `GET`, `POST`, ... requests:

* Access-Control-Allow-Origin
* Access-Control-Allow-Credentials

You can configure the value of these headers as follows:

```elixir
plug CORSPlug, [origin: "example.com"]
```

Please find the list of current defaults in [cors_plug.ex](lib/cors_plug.ex#L5:L13).

