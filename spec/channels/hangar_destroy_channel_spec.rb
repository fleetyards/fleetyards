# frozen_string_literal: true

require 'swagger_helper'
require 'rswag/actioncable_extension'
require 'rswag/actioncable_helpers'

RSpec.describe HangarDestroyChannel, type: :channel, swagger_doc: 'v1/schema.yaml' do
  include Rswag::ActionCableHelpers

  let(:current_user) { create(:user) }
  let(:vehicle) { create(:vehicle, user: current_user, wanted: false) }

  channel 'HangarDestroyChannel' do
    tags 'ActionCable Channels'
    description 'Dedicated channel for vehicle removal events from user hangar'
    
    authentication required: true, method: :current_user

    subscription 'Subscribe to hangar vehicle destroy events' do
      stream_for :current_user
      
      message_schema channel_subscription_schema

      example_message({
        command: 'subscribe',
        identifier: channel_identifier('HangarDestroyChannel')
      })

      run_test! do
        stub_connection current_user: current_user
        subscribe
        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_for(current_user)
      end
    end

    broadcast 'vehicle_destroyed' do
      description 'Sent when a vehicle is removed from the user hangar. Contains the full vehicle object at the time of deletion.'
      
      # Reuses the same Vehicle schema as updates
      message_schema({ "$ref": "#/components/schemas/Vehicle" })

      example_message({
        identifier: channel_identifier('HangarDestroyChannel'),
        message: {
          id: '123e4567-e89b-12d3-a456-426614174000',
          name: 'My Carrack',
          model: {
            id: '456e7890-e89b-12d3-a456-426614174000',
            name: 'Carrack',
            slug: 'carrack'
          },
          # ... rest of vehicle properties
        }
      })

      run_test! do
        stub_connection current_user: current_user
        subscribe
        
        expect {
          vehicle.destroy!
        }.to have_broadcasted_to(current_user).from_channel(HangarDestroyChannel)
      end
    end
  end
end