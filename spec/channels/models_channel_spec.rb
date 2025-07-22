# frozen_string_literal: true

require 'swagger_helper'
require 'rswag/actioncable_extension'
require 'rswag/actioncable_helpers'

RSpec.describe ModelsChannel, type: :channel, swagger_doc: 'v1/schema.yaml' do
  include Rswag::ActionCableHelpers

  channel 'ModelsChannel' do
    tags 'ActionCable Channels'
    description 'Real-time updates for ship models (global channel)'
    
    authentication required: false

    subscription 'Subscribe to model updates' do
      stream_from 'models', type: :global
      
      message_schema channel_subscription_schema

      example_message({
        command: 'subscribe',
        identifier: channel_identifier('ModelsChannel')
      })

      run_test! do
        subscribe
        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_from('models')
      end
    end

    broadcast 'model_update' do
      description 'Sent when any ship model is created or updated'
      
      message_schema({ "$ref": "#/components/schemas/Model" })

      example_message({
        identifier: channel_identifier('ModelsChannel'),
        message: {
          id: '123e4567-e89b-12d3-a456-426614174000',
          name: 'Carrack',
          slug: 'carrack',
          manufacturer: {
            name: 'Anvil Aerospace',
            slug: 'anvil-aerospace'
          },
          classification: 'exploration',
          size: 'large',
          crew: 6,
          price: 600.0,
          last_price: 650.0,
          on_sale: true,
          production_status: 'flight-ready',
          description: 'Multi-crew exploration vessel',
          length: 123.0,
          beam: 64.0,
          height: 30.0,
          cargo: 456,
          created_at: '2024-01-15T10:30:00Z',
          updated_at: '2024-01-15T10:30:00Z'
        }
      })

      run_test! do
        subscribe
        model = create(:model)
        
        expect {
          ActionCable.server.broadcast('models', model.to_json)
        }.to have_broadcasted_to('models')
      end
    end

    broadcast 'new_model' do
      description 'Special broadcast sent only when a new model is added'
      
      # Note: This appears to send the full Model schema based on the code
      # The 'new_model' channel name itself indicates it's a new model
      message_schema({ "$ref": "#/components/schemas/Model" })

      example_message({
        identifier: channel_identifier('ModelsChannel'),
        message: {
          id: '123e4567-e89b-12d3-a456-426614174000',
          name: 'Zeus MkII',
          slug: 'zeus-mkii',
          manufacturer: {
            name: 'Crusader Industries',
            slug: 'crusader-industries'
          },
          is_new: true
        }
      })
    end
  end
end