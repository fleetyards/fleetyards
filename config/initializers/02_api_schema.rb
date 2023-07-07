# frozen_string_literal: true

Rails.application.reloader.to_prepare do
  v1_components_loader = ComponentsLoader.new("v1")
  admin_v1_components_loader = ComponentsLoader.new("admin/v1")

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
        openapi: "3.0.1",
        info: {
          title: "FleetYards.net API",
          version: "v1",
          # description: File.read(Rails.root.join("docs/v1/api.md")),
          "x-logo": {
            url: "http://fleetyards.net/docs/logo.png",
            altText: "FleetYards.net logo"
          }
        },
        servers: api_servers,
        paths: {},
        components: {
          schemas: v1_components_loader.schemas,
          parameters: v1_components_loader.parameters,
          securitySchemes: v1_components_loader.securitySchemes,
          requestBodies: v1_components_loader.requestBodies,
          responses: v1_components_loader.responses,
          headers: v1_components_loader.headers,
          examples: v1_components_loader.examples,
          links: v1_components_loader.links,
          callbacks: v1_components_loader.callbacks
        }.compact
      },
      "admin/v1/schema.yaml" => {
        openapi: "3.0.1",
        info: {
          title: "FleetYards.net Command API",
          version: "v1"
        },
        servers: admin_api_servers,
        paths: {},
        components: {
          schemas: admin_v1_components_loader.schemas,
          parameters: admin_v1_components_loader.parameters,
          securitySchemes: admin_v1_components_loader.securitySchemes,
          requestBodies: admin_v1_components_loader.requestBodies,
          responses: admin_v1_components_loader.responses,
          headers: admin_v1_components_loader.headers,
          examples: admin_v1_components_loader.examples,
          links: admin_v1_components_loader.links,
          callbacks: admin_v1_components_loader.callbacks
        }.compact
      }
    }
  end
end
