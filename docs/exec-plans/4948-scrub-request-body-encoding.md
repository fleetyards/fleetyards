# Middleware: reject a form body Rack cannot parse

## Goal

A request whose form body carries a field in a non-ASCII-compatible encoding gets a 400, not a 500 from inside `Rack::MethodOverride`.

## Context

AppSignal has reported `Encoding::CompatibilityError: incompatible character encodings: UTF-16LE and UTF-8` since March 2023, with no controller attached: it raises in `Rack::MethodOverride`, which reads the form body to look for `_method` before routing.

`Middleware::ScrubHeaderEncoding` only repairs headers, so it never sees this.

Reproducing it showed the source is narrower than "a UTF-16LE body". An `application/x-www-form-urlencoded` body cannot cause it: Rack unescapes every pair as UTF-8, so bad bytes come out as an invalid UTF-8 string, not a UTF-16LE one. The trigger is a **multipart** part without a filename that declares `Content-Type: text/plain; charset=UTF-16LE`. `Rack::Multipart::Parser#tag_multipart_encoding` forces the part's *name* into that charset, and `QueryParser#_normalize_params` then calls `name.index("[", 1)`, which raises because UTF-16LE is not ASCII-compatible. `Rack::MethodOverride` rescues Rack's own parameter errors, but not this one.

Resolves #4948

## Decisions

### D1 — Reject in a middleware, rather than mute in AppSignal

`ignore_errors` would hide every future `Encoding::CompatibilityError`, and the class is generic enough that an unrelated one would disappear with it. The request is malformed, so a 400 is the honest answer.

### D2 — Parse exactly where Rack::MethodOverride would

The new `Middleware::RejectMalformedFormBody` sits directly before `Rack::MethodOverride` and runs the same check it does: a POST whose body is form data or parseable data. It calls `Rack::Request#POST` and answers 400 on `Encoding::CompatibilityError`.

Rack memoizes the parsed form in the env, so a well-formed body is still parsed once, and a JSON body or any non-POST request is never read. Other parse errors are left for `Rack::MethodOverride` to report as it did before; Rack caches the error in the env, so it sees the same one.

### D3 — QUERY_STRING is left alone

The issue suspected the query string is the same class of bug. It is not: it is unescaped as UTF-8 like a urlencoded body, and `Rack::MethodOverride` never reads it. Invalid bytes there are already turned into `ActionController::BadRequest` by Rails.

## What changed

1. `lib/middleware/reject_malformed_form_body.rb` — the middleware.
2. `config/initializers/04_reject_malformed_form_body.rb` — inserted before `Rack::MethodOverride`.
3. Unit tests for the middleware and one integration test through the full stack.

## Intent Verification

- [x] **The error reproduces** — a unit test shows the multipart body raising inside `Rack::MethodOverride` alone
- [x] **The full app answers 400** — the integration test errors with the same `Encoding::CompatibilityError` when the initializer is removed
- [x] **Method override still works** for a well-formed urlencoded body
- [x] **A JSON body is not read**

## Key files

| File | Role |
|------|------|
| `lib/middleware/reject_malformed_form_body.rb` | The check |
| `config/initializers/04_reject_malformed_form_body.rb` | Its place in the stack |
| `lib/middleware/scrub_header_encoding.rb` | The header counterpart it mirrors |

## Progress

- [x] Reproduce
- [x] Middleware and tests
