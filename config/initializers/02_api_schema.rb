# frozen_string_literal: true

Rails.application.reloader.to_prepare do
  v1_components_loader = ComponentsLoader.new("v1")
  admin_v1_components_loader = ComponentsLoader.new("admin/v1")
  shared_v1_components_loader = ComponentsLoader.new("shared/v1")

  Rails.application.configure do
    api_servers = [
      {
        url: API_ENDPOINT,
        description: "Dev Server"
      },
      {
        url: "https://api.fleetyards.net/v1",
        description: "Production Server"
      }, {
        url: "https://api.fleetyards.dev/v1",
        description: "Staging Server"
      }
    ]

    admin_api_servers = [
      {
        url: ADMIN_API_ENDPOINT,
        description: "Dev Server"
      }, {
        url: "http://admin.fleetyards.test/api/v1",
        description: "Production Server"
      }, {
        url: "https://admin.fleetyards.dev/api/v1",
        description: "Staging Server"
      }
    ]

    config.api_schema.schemas = {
      "v1/schema.yaml" => {
        openapi: Rails.configuration.api_schema.oas_version,
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
        servers: api_servers,
        security: [],
        paths: {},
        components: {
          parameters: shared_v1_components_loader.parameters.merge(v1_components_loader.parameters),
          schemas: shared_v1_components_loader.schemas.merge(v1_components_loader.schemas),
          securitySchemes: shared_v1_components_loader.security_schemes.merge(v1_components_loader.security_schemes)
        }.compact
      },
      "admin/v1/schema.yaml" => {
        openapi: Rails.configuration.api_schema.oas_version,
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
        servers: admin_api_servers,
        security: [
          SessionCookie: []
        ],
        paths: {},
        components: {
          parameters: shared_v1_components_loader.parameters.merge(admin_v1_components_loader.parameters),
          schemas: shared_v1_components_loader.schemas.merge(admin_v1_components_loader.schemas),
          securitySchemes: shared_v1_components_loader.security_schemes.merge(admin_v1_components_loader.security_schemes)
        }.compact
      }
    }
  end
end
