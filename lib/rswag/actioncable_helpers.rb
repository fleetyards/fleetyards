# frozen_string_literal: true

module Rswag
  module ActionCableHelpers
    # Helper methods for common ActionCable patterns
    
    def channel_subscription_schema
      {
        type: :object,
        properties: {
          command: { type: :string, enum: ['subscribe'] },
          identifier: { type: :string, description: 'JSON string containing channel class and params' }
        },
        required: ['command', 'identifier']
      }
    end

    def channel_unsubscription_schema
      {
        type: :object,
        properties: {
          command: { type: :string, enum: ['unsubscribe'] },
          identifier: { type: :string, description: 'JSON string containing channel class and params' }
        },
        required: ['command', 'identifier']
      }
    end

    def channel_message_schema(data_schema = {})
      {
        type: :object,
        properties: {
          identifier: { type: :string },
          message: {
            type: :object,
            properties: data_schema
          }
        },
        required: ['identifier', 'message']
      }
    end

    def broadcast_message_schema(data_schema = {})
      {
        type: :object,
        properties: {
          type: { type: :string, enum: ['ping', 'welcome', 'disconnect', 'confirm_subscription', 'reject_subscription', 'broadcast'] },
          identifier: { type: :string },
          message: data_schema
        }
      }
    end

    # Helper to generate channel identifier
    def channel_identifier(channel_class, params = {})
      { channel: channel_class }.merge(params).to_json
    end

    # Helper to document common broadcast patterns
    def document_model_broadcast(model_name, attributes)
      {
        type: :object,
        properties: attributes,
        required: attributes.keys.select { |k| k.to_s != 'id' }
      }
    end

    # Helper for user-specific channels
    def user_channel_params
      {
        user_id: {
          type: :integer,
          description: 'Automatically set from current_user',
          readOnly: true
        }
      }
    end

    # Helper for pagination in broadcasts
    def paginated_broadcast_schema(item_schema)
      {
        type: :object,
        properties: {
          items: {
            type: :array,
            items: item_schema
          },
          meta: {
            type: :object,
            properties: {
              total: { type: :integer },
              page: { type: :integer },
              per_page: { type: :integer }
            }
          }
        }
      }
    end
  end
end

# Make helpers available in specs
RSpec.configure do |config|
  config.include Rswag::ActionCableHelpers, type: :channel
end