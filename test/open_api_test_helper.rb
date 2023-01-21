# frozen_string_literal: true

module OpenApiTestHelper
  include Committee::Test::Methods

  def committee_options
    schema ||= begin
      schema_path = Rails.root.join("schema.yaml")
      data = YAML.load_file(Rails.root.join("schema.yaml"))
      openapi = OpenAPIParser.parse_with_filepath(data, schema_path)
      Committee::Drivers::OpenAPI3::Driver.new.parse(openapi)
    end

    @committee_options ||= {
      schema:,
      prefix: "/api/v2",
      strict: true,
      coerce_date_times: true,
      parse_response_by_content_type: true,
      query_hash_key: "rack.request.query_hash",
      params_key: "action_dispatch.request.request_parameters"
    }
  end

  def request_object
    request
  end

  def response_data
    [response.status, response.headers, response.body]
  end
end
