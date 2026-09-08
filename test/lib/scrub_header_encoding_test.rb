# frozen_string_literal: true

require "test_helper"

class ScrubHeaderEncodingTest < ActiveSupport::TestCase
  # Puma hands header values over tagged as UTF-8, invalid bytes and all --
  # which is what makes Rack's regexps raise. A `\xFF` literal in a UTF-8
  # source file is binary, so the encoding has to be set by hand.
  def invalid_utf8(value)
    value.dup.force_encoding("UTF-8")
  end

  def call(env)
    forwarded = nil
    app = lambda do |inner_env|
      forwarded = inner_env
      [200, {}, []]
    end

    Middleware::ScrubHeaderEncoding.new(app).call(env)
    forwarded
  end

  test "drops invalid bytes from a scrubbed header" do
    env = call("HTTP_COOKIE" => invalid_utf8("_fleetyards_session=abc\xFFdef"))

    assert_equal "_fleetyards_session=abcdef", env["HTTP_COOKIE"]
    assert_predicate env["HTTP_COOKIE"], :valid_encoding?
  end

  test "keeps a header that is already valid UTF-8" do
    env = call("HTTP_USER_AGENT" => "Mozilla/5.0 (Ünicode)")

    assert_equal "Mozilla/5.0 (Ünicode)", env["HTTP_USER_AGENT"]
  end

  test "leaves a header the request did not send unset" do
    env = call({"HTTP_COOKIE" => nil})

    assert_nil env["HTTP_COOKIE"]
  end

  test "leaves headers outside the list alone" do
    value = invalid_utf8("abc\xFFdef")
    env = call("HTTP_X_CUSTOM" => value)

    assert_equal value, env["HTTP_X_CUSTOM"]
  end
end
