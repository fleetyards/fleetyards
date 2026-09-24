# frozen_string_literal: true

require "test_helper"

class RejectMalformedFormBodyTest < ActiveSupport::TestCase
  # Rack tags a multipart field name with the charset of its text/plain part,
  # and a UTF-16LE name cannot be searched with the UTF-8 brackets the query
  # parser looks for.
  UTF16_MULTIPART_BODY = [
    "--boundary",
    "Content-Disposition: form-data; name=\"user\"",
    "Content-Type: text/plain; charset=UTF-16LE",
    "",
    "value",
    "--boundary--",
    ""
  ].join("\r\n").freeze

  def stack
    inner = lambda do |env|
      @forwarded = env
      [200, {}, ["ok"]]
    end

    Middleware::RejectMalformedFormBody.new(Rack::MethodOverride.new(inner))
  end

  def post(body, content_type)
    env = Rack::MockRequest.env_for("/", :method => "POST", :input => body, "CONTENT_TYPE" => content_type)
    stack.call(env)
  end

  test "the body raises inside Rack::MethodOverride on its own" do
    env = Rack::MockRequest.env_for(
      "/", :method => "POST", :input => UTF16_MULTIPART_BODY, "CONTENT_TYPE" => "multipart/form-data; boundary=boundary"
    )

    assert_raises(Encoding::CompatibilityError) do
      Rack::MethodOverride.new(->(_env) { [200, {}, []] }).call(env)
    end
  end

  test "rejects a form body with an incompatible encoding with a 400" do
    status, _headers, _body = post(UTF16_MULTIPART_BODY, "multipart/form-data; boundary=boundary")

    assert_equal 400, status
    assert_nil @forwarded
  end

  test "forwards a well-formed form body and keeps the method override" do
    status, _headers, _body = post("_method=delete&name=Ünicode", "application/x-www-form-urlencoded")

    assert_equal 200, status
    assert_equal "DELETE", @forwarded["REQUEST_METHOD"]
    assert_equal "Ünicode", Rack::Request.new(@forwarded).POST["name"]
  end

  test "leaves a JSON body unread" do
    input = StringIO.new('{"name":"value"}')
    env = Rack::MockRequest.env_for("/", :method => "POST", :input => input, "CONTENT_TYPE" => "application/json")

    status, _headers, _body = stack.call(env)

    assert_equal 200, status
    assert_equal 0, @forwarded["rack.input"].pos
  end

  test "leaves the body of a non-POST request to the app" do
    env = Rack::MockRequest.env_for(
      "/", :method => "PATCH", :input => UTF16_MULTIPART_BODY, "CONTENT_TYPE" => "multipart/form-data; boundary=boundary"
    )

    status, _headers, _body = stack.call(env)

    assert_equal 200, status
  end

  test "leaves other malformed bodies to Rack::MethodOverride" do
    status, _headers, _body = post("a[]=1&a[b]=2", "application/x-www-form-urlencoded")

    assert_equal 200, status
    assert_equal "POST", @forwarded["REQUEST_METHOD"]
  end
end
