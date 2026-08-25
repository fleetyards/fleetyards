# frozen_string_literal: true

cable_uri = URI.parse(CABLE_ENDPOINT)
cable_host = (cable_uri.port == cable_uri.default_port) ? cable_uri.host : "#{cable_uri.host}:#{cable_uri.port}"

cable_servers = {
  development: {
    host: cable_host,
    pathname: cable_uri.path,
    protocol: cable_uri.scheme,
    description: "Dev Server"
  },
  production: {
    host: "fleetyards.net",
    pathname: "/cable",
    protocol: "wss",
    description: "Production Server"
  },
  staging: {
    host: "fleetyards.dev",
    pathname: "/cable",
    protocol: "wss",
    description: "Staging Server"
  }
}

AsyncapiCable.configure do |config|
  config.schemas = {
    "cable/v1/schema" => {
      info: {
        title: "FleetYards.net Cable API",
        version: "v1",
        license: {
          name: "GNU General Public License v3.0",
          url: "https://github.com/fleetyards/fleetyards/blob/main/LICENSE"
        }
      },
      servers: cable_servers,
      component_scope: :cable
    },
    "cable/admin/v1/schema" => {
      info: {
        title: "FleetYards.net Command Cable API",
        version: "v1",
        license: {
          name: "GNU General Public License v3.0",
          url: "https://github.com/fleetyards/fleetyards/blob/main/LICENSE"
        }
      },
      servers: cable_servers,
      component_scope: :cable_admin
    }
  }

  config.schema_output_dir = "asyncapi"
  config.schema_output_format = :yaml

  # Not :enabled — broadcasts run from after_save/after_commit callbacks, so a
  # raise on a payload mismatch would roll back the write that triggered it.
  config.validation_mode = :warn_only
end
