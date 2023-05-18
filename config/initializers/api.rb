# frozen_string_literal: true

Rails.application.reloader.to_prepare do
  components_loader = ComponentsLoader.new

  Rails.application.configure do
    config.api = {
      "v1/schema.yaml" => {
        openapi: "3.0.1",
        info: {
          title: "FleetYards.net API v1",
          version: "v1",
          description: File.read(Rails.root.join("docs/v1/api.md")),
          "x-logo": {
            url: "http://fleetyards.test/docs/logo.png",
            altText: "FleetYards.net logo"
          }
        },
        servers: [
          {
            url: "{protocol}://{host}",
            variables: {
              host: {
                default: "api.fleetyards.net/v1"
              },
              protocol: {
                enum: %w[https http],
                default: "https"
              }
            }
          }, {
            url: "https://api.fleetyards.net/v1",
            description: "Production Server"
          }, {
            url: "https://stage.fleetyards.net/api/v1",
            description: "Test Server"
          }, {
            url: "http://api.fleetyards.test/v1",
            description: "Local Test Server"
          }
        ],
        paths: {},
        components: {
          schemas: components_loader.schemas("v1")
        }
      },
      "admin/v1/schema.yaml" => {
        openapi: "3.0.1",
        info: {
          title: "FleetYards.net Command API v1",
          version: "v1"
        },
        servers: [
          {
            url: "{adminHost}",
            variables: {
              adminHost: {
                default: "https://admin.fleetyards.net/api/v1"
              }
            }
          }, {
            url: "http://admin.fleetyards.test/api/v1"
          }
        ],
        paths: {}
      }
    }
  end
end
