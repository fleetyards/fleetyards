# frozen_string_literal: true

module OpenApiTestHelper
  include Committee::Test::Methods

  def committee_options
    schema ||= begin
      schema_path = Rails.root.join('schema.yaml')
      data = YAML.load_file(Rails.root.join('schema.yaml'))
      openapi = OpenAPIParser.parse_with_filepath(data, schema_path)
      Committee::Drivers::OpenAPI3::Driver.new.parse(openapi)
    end

    @committee_options ||= {
      schema: schema,
      prefix: '/api/v2',
      query_hash_key: 'rack.request.query_hash',
      parse_response_by_content_type: false
    }
  end

  def request_object
    request
  end

  def response_data
    [response.status, response.headers, response.body]
  end
end
