# frozen_string_literal: true

require 'swagger_helper'
require 'rswag/actioncable_extension'
require 'rswag/actioncable_helpers'

RSpec.describe HangarChannel, type: :channel, swagger_doc: 'v1/schema.yaml' do
  include Rswag::ActionCableHelpers

  let(:current_user) { create(:user) }
  let(:vehicle) { create(:vehicle, user: current_user) }

  channel 'HangarChannel' do
    tags 'ActionCable Channels'
    description 'Real-time updates for user hangar vehicles'
    
    authentication required: true, method: :current_user

    subscription 'Subscribe to hangar updates' do
      stream_for :current_user
      
      message_schema channel_subscription_schema

      example_message({
        command: 'subscribe',
        identifier: channel_identifier('HangarChannel')
      })

      run_test! do
        stub_connection current_user: current_user
        subscribe
        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_for(current_user)
      end
    end

    broadcast 'vehicle_update' do
      description 'Sent when a vehicle in the user hangar is updated'
      
      message_schema({ "$ref": "#/components/schemas/Vehicle" })

      example_message({
        identifier: channel_identifier('HangarChannel'),
        message: {
          id: '123e4567-e89b-12d3-a456-426614174000',
          name: 'My Carrack',
          model_id: '456e7890-e89b-12d3-a456-426614174000',
          model_name: 'Carrack',
          manufacturer: 'Anvil Aerospace',
          purchased: true,
          flagship: true,
          name_visible: true,
          public: true,
          loaner: false,
          created_at: '2024-01-15T10:30:00Z',
          updated_at: '2024-01-15T10:30:00Z'
        }
      })

      run_test! do
        stub_connection current_user: current_user
        subscribe
        
        expect {
          vehicle.update!(name: 'Updated Name')
        }.to have_broadcasted_to(current_user).from_channel(HangarChannel)
      end
    end

    # Note: Vehicle destroy events are actually sent through HangarDestroyChannel, not HangarChannel
    # This is documented here for completeness
  end
end