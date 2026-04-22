# frozen_string_literal: true

require "rails_helper"
require "openapi_ruby/rspec"

# Backwards compatibility for rswag patterns not natively supported by openapi-ruby.
module OpenapiRswagCompat
  def submit_openapi_request(metadata)
    operation = find_in_metadata(metadata, :openapi_operation)

    if operation
      # rswag used `parameter name: :input, in: :body` to send request bodies.
      # openapi-ruby expects `let(:request_body)` instead.
      if resolve_let(:request_body).nil?
        body_param = operation.parameters.find { |p| p["in"] == "body" }
        if body_param
          val = resolve_let(body_param["name"]&.to_sym)
          define_singleton_method(:request_body) { val } unless val.nil?
        end
      end

      # rswag supported `parameter "$ref": "#/components/parameters/..."` which
      # creates parameters without a "name" field. The adapter's parameter loop
      # calls `param["name"].to_sym` which fails on nil. Remove $ref params
      # before the adapter processes them — they're schema-only metadata.
      operation.parameters.reject! { |p| p["name"].nil? }
    end

    super
  end
end

OpenapiRuby::Adapters::RSpec::ExampleHelpers.prepend(OpenapiRswagCompat)
