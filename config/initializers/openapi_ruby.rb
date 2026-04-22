# frozen_string_literal: true

OpenapiRuby.configure do |config|
  config.schemas = {
    "v1/schema" => {
      openapi_version: "3.0.3",
      info: {
        title: "FleetYards.net API",
        version: "v1",
        license: {
          name: "GNU General Public License v3.0",
          url: "https://github.com/fleetyards/fleetyards/blob/main/LICENSE"
        },
        "x-logo": {
          url: "https://fleetyards.net/docs/logo.png",
          altText: "FleetYards.net logo"
        }
      },
      servers: [
        {url: API_ENDPOINT, description: "Dev Server"},
        {url: "https://api.fleetyards.net/v1", description: "Production Server"},
        {url: "https://api.fleetyards.dev/v1", description: "Staging Server"}
      ],
      security: [],
      component_scope: :v1,
      prefix: URI.parse(API_ENDPOINT).path
    },
    "admin/v1/schema" => {
      openapi_version: "3.0.3",
      info: {
        title: "FleetYards.net Command API",
        version: "v1",
        license: {
          name: "GNU General Public License v3.0",
          url: "https://github.com/fleetyards/fleetyards/blob/main/LICENSE"
        },
        "x-logo": {
          url: "https://fleetyards.net/docs/logo.png",
          altText: "FleetYards.net logo"
        }
      },
      servers: [
        {url: ADMIN_API_ENDPOINT, description: "Dev Server"},
        {url: "http://admin.fleetyards.test/api/v1", description: "Production Server"},
        {url: "https://admin.fleetyards.dev/api/v1", description: "Staging Server"}
      ],
      security: [
        {SessionCookie: []}
      ],
      component_scope: :admin,
      prefix: URI.parse(ADMIN_API_ENDPOINT).path
    },
    "oauth/v1/schema" => {
      openapi_version: "3.0.3",
      info: {
        title: "FleetYards.net OAuth API",
        version: "v1",
        license: {
          name: "GNU General Public License v3.0",
          url: "https://github.com/fleetyards/fleetyards/blob/main/LICENSE"
        }
      },
      servers: [
        {url: OAUTH_ENDPOINT, description: "Dev Server"},
        {url: "https://fleetyards.net/oauth", description: "Production Server"},
        {url: "https://fleetyards.dev/oauth", description: "Staging Server"}
      ],
      security: [],
      component_scope: :oauth
    }
  }

  config.component_paths = ["app/api_components"]
  config.component_scope_paths = {
    "v1" => :v1,
    "admin/v1" => :admin,
    "oauth/v1" => :oauth,
    "shared/v1" => [:v1, :admin]
  }

  config.camelize_keys = false
  config.schema_output_format = :yaml
  config.schema_output_dir = "swagger"

  config.request_validation = (Rails.env.test? || ENV.fetch("SKIP_COMMITTEE", false)) ? :disabled : :enabled
  config.response_validation = :disabled
  config.strict_reference_validation = true

  config.auto_validation_error_response = true
  config.validation_error_schema = {
    "type" => "object",
    "properties" => {
      "code" => {"type" => "string"},
      "message" => {"type" => "string"}
    },
    "required" => %w[code message]
  }

  config.error_handler = Class.new(OpenapiRuby::Middleware::ErrorHandler) {
    def invalid_request(errors)
      body = {code: "validation_error", message: errors.first}.to_json
      [400, {"content-type" => "application/json"}, [body]]
    end
  }.new
end

# Force-load all component files so they register in the Registry.
# Required for security scheme resolution in tests and middleware.
Rails.application.config.after_initialize do
  OpenapiRuby::Components::Loader.new.load!
end
