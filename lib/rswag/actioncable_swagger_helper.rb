# frozen_string_literal: true

# Integration with existing swagger_helper.rb
module Rswag
  module ActionCableSwaggerHelper
    def self.enhance_swagger_config(config)
      # Add WebSocket server information
      config.openapi_specs.each do |spec_name, spec_config|
        # Add WebSocket servers alongside HTTP servers
        ws_servers = spec_config[:servers].map do |server|
          ws_url = server[:url].gsub(/^http/, 'ws').gsub(/\/v1$/, '/cable')
          {
            url: ws_url,
            protocol: 'ws',
            description: "#{server[:description]} (WebSocket)"
          }
        end

        # Add x-servers extension for WebSocket endpoints
        spec_config[:'x-servers'] ||= {}
        spec_config[:'x-servers'][:websocket] = ws_servers

        # Add ActionCable-specific components
        spec_config[:components] ||= {}
        spec_config[:components][:'x-actioncable'] = {
          connection: {
            authentication: {
              type: 'cookie',
              description: 'Uses same authentication as HTTP API'
            },
            endpoint: '/cable',
            protocols: ['actioncable-v1-json']
          },
          messageFormats: {
            subscription: {
              type: 'object',
              properties: {
                command: { type: 'string', enum: ['subscribe', 'unsubscribe'] },
                identifier: { type: 'string' }
              }
            },
            message: {
              type: 'object',
              properties: {
                command: { type: 'string', enum: ['message'] },
                identifier: { type: 'string' },
                data: { type: 'string' }
              }
            },
            confirmation: {
              type: 'object',
              properties: {
                type: { type: 'string', enum: ['confirm_subscription', 'reject_subscription'] },
                identifier: { type: 'string' }
              }
            },
            broadcast: {
              type: 'object',
              properties: {
                identifier: { type: 'string' },
                message: { type: 'object' }
              }
            }
          }
        }
      end
    end

    # Method to merge channel documentation into OpenAPI spec
    def self.merge_channel_docs(swagger_doc, channel_docs)
      swagger_doc[:'x-actioncable-channels'] ||= {}
      swagger_doc[:'x-actioncable-channels'].merge!(channel_docs[:'x-actioncable-channels']) if channel_docs[:'x-actioncable-channels']
    end
  end
end

# Monkey patch to automatically load ActionCable extension
if defined?(RSpec)
  RSpec.configure do |config|
    config.before(:suite) do
      if defined?(Rswag) && RSpec.configuration.openapi_specs
        Rswag::ActionCableSwaggerHelper.enhance_swagger_config(RSpec.configuration)
      end
    end
  end
end