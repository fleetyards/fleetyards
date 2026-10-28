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

  test "validates an OpenAPI document after another thread resolved the meta-schema's root ref" do
    document = JSONSchemer.openapi31_document
    then_keyword = document.parsed.fetch("allOf").parsed.first.parsed.fetch("then")
    openapi_root = then_keyword.parsed_schema.parsed.fetch("$ref").ref_schema
    extensions_ref = openapi_root.parsed.fetch("$ref")
    extensions_ref.instance_variable_set(:@ref_schema, nil)

    openapi_root.root.resolve_ref(extensions_ref.ref_uri)

    assert_empty document.validate({"openapi" => "3.1.0", "info" => {"title" => "t", "version" => "1"}, "paths" => {}}).to_a
  end
end
