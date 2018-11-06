CorsPlug
========
[![Build Status](https://travis-ci.org/mschae/cors_plug.svg)](https://travis-ci.org/mschae/cors_plug)
[![Hex.pm](https://img.shields.io/hexpm/v/cors_plug.svg)]()
[![Hex.pm](https://img.shields.io/hexpm/l/cors_plug.svg)]()

An [Elixir Plug](http://github.com/elixir-lang/plug) to add [CORS](http://www.w3.org/TR/cors/).

## Usage

1. Add this plug to your `mix.exs` dependencies:

```elixir
def deps do
  # ...
  {:cors_plug, "~> 2.0"},
  #...
end
```

When used together with the awesomeness that's the [Phoenix Framework](http://www.phoenixframework.org/)
please note that putting the CORSPlug in a pipeline won't work as they are only invoked for
matched routes.

I therefore recommend to put it in `lib/your_app/endpoint.ex`:

```elixir
defmodule YourApp.Endpoint do
  use Phoenix.Endpoint, otp_app: :your_app

  # ...
  plug CORSPlug

  plug YourApp.Router
end
```

Alternatively you can add options routes, as suggested by @leighhalliday

```elixir
scope "/api", PhoenixApp do
  pipe_through :api

  resources "/articles", ArticleController
  options   "/articles", ArticleController, :options
  options   "/articles/:id", ArticleController, :options
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
* Access-Control-Expose-Headers
* Access-Control-Allow-Credentials

You can configure allowed origins using one of the following methods:

### Using a list

```elixir
plug CORSPlug, origin: ["http://example1.com", "http://example2.com"]
```

### Using a regex

```elixir
plug CORSPlug, origin: ~r/https?.*example\d?\.com$/
```

### Using the config.exs file

```elixir
config :cors_plug,
  origin: ["http://example.com"],
  max_age: 86400,
  methods: ["GET", "POST"]
```

### Using a `function/0` that returns the allowed origin as a string

**Caveat: Anonymous functions are not possible as they can't be quoted.**

```elixir
plug CORSPlug, origin: &MyModule.my_fun/0

def my_fun do
  http://example.com
end
```

### send_preflight_response?

There may be times when you would like to retain control over the response sent to OPTIONS requests. If you
would like CORSPlug to only set headers, then set the `send_preflight_response?` option to false.

```elixir
plug CORSPlug, send_preflight_response?: false

# or in the app config

config :cors_plug,
  send_preflight_response?: false
```

Please note that options passed to the plug overrides app config but app config
overrides default options.

Please find the list of current defaults in
[cors_plug.ex](lib/cors_plug.ex#L5:L26).

**As per the [W3C Recommendation](https://www.w3.org/TR/cors/#access-control-allow-origin-response-header)
the string `null` is returned when no configured origin matched the request.**


## License

Copyright 2017 Michael Schaefermeyer

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
