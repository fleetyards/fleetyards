# frozen_string_literal: true

require "test_helper"

class JSONSchemerResolveRefTest < ActiveSupport::TestCase
  setup do
    @schema = JSONSchemer.schema({
      "$defs" => {"name" => {"type" => "string"}},
      "$ref" => "#/$defs/name"
    })
    @ref = @schema.parsed.fetch("$ref")
  end

  test "leaves the memoized ref URI intact" do
    @schema.resolve_ref(@ref.ref_uri)

    assert_equal "/$defs/name", @ref.ref_uri.fragment
  end

  test "resolves the same ref to the same schema every time" do
    first = @schema.resolve_ref(@ref.ref_uri)
    second = @schema.resolve_ref(@ref.ref_uri)

    assert_same first, second
    refute_same @schema, second
  end
end
