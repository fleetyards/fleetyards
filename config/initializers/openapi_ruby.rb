# frozen_string_literal: true

OpenapiRuby.configure do |config|
  config.schemas = {
    "v1/schema" => {
      openapi_version: "3.0.3",
      info: {
        "title" => "FleetYards.net API",
        "version" => "v1",
        "license" => {
          "name" => "GNU General Public License v3.0",
          "url" => "https://github.com/fleetyards/fleetyards/blob/main/LICENSE"
        },
        "x-logo" => {
          "url" => "https://fleetyards.net/docs/logo.png",
          "altText" => "FleetYards.net logo"
        }
      },
      servers: [
        {"url" => API_ENDPOINT, "description" => "Dev Server"},
        {"url" => "https://api.fleetyards.net/v1", "description" => "Production Server"},
        {"url" => "https://api.fleetyards.dev/v1", "description" => "Staging Server"}
      ],
      security: [],
      component_scope: :v1,
      prefix: URI.parse(API_ENDPOINT).path
    },
    "admin/v1/schema" => {
      openapi_version: "3.0.3",
      info: {
        "title" => "FleetYards.net Command API",
        "version" => "v1",
        "license" => {
          "name" => "GNU General Public License v3.0",
          "url" => "https://github.com/fleetyards/fleetyards/blob/main/LICENSE"
        },
        "x-logo" => {
          "url" => "https://fleetyards.net/docs/logo.png",
          "altText" => "FleetYards.net logo"
        }
      },
      servers: [
        {"url" => ADMIN_API_ENDPOINT, "description" => "Dev Server"},
        {"url" => "http://admin.fleetyards.test/api/v1", "description" => "Production Server"},
        {"url" => "https://admin.fleetyards.dev/api/v1", "description" => "Staging Server"}
      ],
      security: [
        {"SessionCookie" => []}
      ],
      component_scope: :admin,
      prefix: URI.parse(ADMIN_API_ENDPOINT).path
    },
    "oauth/v1/schema" => {
      openapi_version: "3.0.3",
      info: {
        "title" => "FleetYards.net OAuth API",
        "version" => "v1",
        "license" => {
          "name" => "GNU General Public License v3.0",
          "url" => "https://github.com/fleetyards/fleetyards/blob/main/LICENSE"
        }
      },
      servers: [
        {"url" => OAUTH_ENDPOINT, "description" => "Dev Server"},
        {"url" => "https://fleetyards.net/oauth", "description" => "Production Server"},
        {"url" => "https://fleetyards.dev/oauth", "description" => "Staging Server"}
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
    "shared/v1" => :shared
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
  loader = OpenapiRuby::Components::Loader.new
  loader.load!

  # Workaround for two gem bugs in the Loader's scope inference:
  #
  # 1. Cross-scope inheritance: when Admin::V1::Schemas::X inherits from
  #    V1::Schemas::X, the parent gets loaded during the admin file require,
  #    so the Loader maps it to the admin scope instead of v1.
  #
  # 2. Shared scope: the Loader sets _component_scopes = [] for shared
  #    components but doesn't set _component_scopes_explicitly_set, so they're
  #    excluded when filtering by scope.
  #
  # Fix: re-infer scopes from class name prefixes after loading.
  scope_prefixes = {
    "Admin::V1::" => :admin,
    "Oauth::V1::" => :oauth,
    "V1::" => :v1
  }

  OpenapiRuby::Components::Registry.instance.all_registered_classes.each do |klass|
    next if klass._component_scopes_explicitly_set
    next unless klass.name

    if klass.name.start_with?("Shared::V1::")
      klass._component_scopes = []
      klass._component_scopes_explicitly_set = true
    else
      matched = scope_prefixes.find { |prefix, _| klass.name.start_with?(prefix) }
      next unless matched

      expected_scope = matched[1]
      next if klass._component_scopes == [expected_scope]

      OpenapiRuby::Components::Registry.instance.unregister(klass)
      klass._component_scopes = [expected_scope]
      OpenapiRuby::Components::Registry.instance.register(klass)
    end
  end
end
