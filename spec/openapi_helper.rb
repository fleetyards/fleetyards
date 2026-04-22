# frozen_string_literal: true

require "rails_helper"
require "openapi_ruby/rspec"

# Backwards compatibility for rswag patterns not natively supported by openapi-ruby.
#
# Test execution compat (OpenapiRswagCompat):
#   - Resolves `parameter in: :body` as the request body
#   - Removes $ref parameters without a name field
#
# Schema generation compat (OpenapiRswagSchemaCompat):
#   - Converts `in: body` params to requestBody
#   - Wraps bare `type` params in a `schema` object
#   - Preserves $ref-only parameters as-is

module OpenapiRswagCompat
  def submit_openapi_request(metadata)
    operation = find_in_metadata(metadata, :openapi_operation)

    if operation
      if resolve_let(:request_body).nil?
        body_param = operation.parameters.find { |p| p["in"] == "body" }
        if body_param
          val = resolve_let(body_param["name"]&.to_sym)
          define_singleton_method(:request_body) { val } unless val.nil?
        end
      end

      operation.parameters.reject! { |p| p["name"].nil? }
    end

    super
  end
end

OpenapiRuby::Adapters::RSpec::ExampleHelpers.prepend(OpenapiRswagCompat)

# Patch schema generation to handle rswag parameter patterns.
module OpenapiRswagSchemaCompat
  def to_openapi
    result = super

    # Convert `in: body` parameters to requestBody
    if result["parameters"]&.any? { |p| p["in"] == "body" }
      body_param = result["parameters"].find { |p| p["in"] == "body" }
      result["parameters"] = result["parameters"].reject { |p| p["in"] == "body" }
      result.delete("parameters") if result["parameters"].empty?

      unless result["requestBody"]
        schema = body_param["schema"]
        content_type = @consumes_list&.first || "application/json"
        result["requestBody"] = {
          "required" => body_param.fetch("required", false),
          "content" => {content_type => {"schema" => schema}}
        }
      end
    end

    # Wrap bare `type` on parameters into a `schema` object
    result["parameters"]&.each do |param|
      if param["type"] && !param["schema"]
        param["schema"] = {"type" => param.delete("type")}
      end
    end

    result
  end
end

OpenapiRuby::DSL::OperationContext.prepend(OpenapiRswagSchemaCompat)
