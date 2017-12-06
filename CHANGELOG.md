# Changelog

## v.1.5.0

* Enhancements
  * Allow configuration of origin via function (thanks @mauricioszabo).

## v.1.4.0

* Enhancements
  * Allows both `*` as well as specific domains in the `origins` config, returns
    the corresponding value (thanks @mustafaturan)
* Fixes
  * Don't overwrite `vary` header values with `"Origin"`, instead append it.
  * Don't set `vary` header to empty string if not needed.
  * Use `Plug.Conn.merge_resp_headers/2`

New major release because of the `vary` header changes, I don't expect this
to break anything.

## v.1.3.0

* Enhancements
  * Allows configuration via app config (see [README.md](README.md), thanks
    @TokiTori).

## v.1.2.1

* Fixes
  * Match for exact origin only (thanks @somlor and @JordanAdams).
  * Add Vary to response header (thanks @linjunpop).

## v.1.2.0

* Fixes
  * Remove cowboy dependency. Plug should be server-agnostic and this plug does
    not need cowboy. Thanks to @hauleth and @ewitchin for making me aware.

As I changed dependency this is a minor release. I don't anticipate any
regressions tho.

## v1.1.4

* Fixes
  * Add method parens to suppress Elixir 1.4.0 warnings (thanks @seivan).

## v1.1.3

* Enhancements
  * Support regex for `origin` (thanks @somlor)

## v1.1.2

* Enhancements
  * Allow client to set `allow-headers` by sending `request-headers` when using
    a wildcard.

This enhancement is brought to you by @arathunku

## v1.1.1

* Fixes
  * Return "null" instead of null when no origin matches.

Many thanks to @somlor for the fix!

## v1.1.0

* Enhancements
  * Allow multiple origins. When configuring you can now pass a list for
`origins` (`plug: CORSPlug, origin: ~w(example1.com example2.com)`).
* Fixes
  * `Access-Control-Expose-Headers` now works

Both of these have been brought to you by @jer-k - many thanks!

## v1.0.0

* Fixes
  * Don't override headers. Earlier headers would've been overriden by the
    CORS Plug. Amazing that this hasn't popped up before...

As this makes a backward-incompatible change (no longer overriding headers
this is a new major).

## v0.1.4

* Enhancements
  * Add [`Access-Control-Expose-Headers`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS#Access-Control-Expose-Headers) (thanks @jaketrent)

## v0.1.3

* Enhancements
  * Add license
  * Improve readme (thanks @leighhalliday, @patricksrobertson)
  * Simplify travis.yml (thanks @lowks)

## v.0.1.2

* Release plug dependency
