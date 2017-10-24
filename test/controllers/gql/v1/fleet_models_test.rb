# frozen_string_literal: true

# frozen_string_literal: true

require "test_helper"

module Gql
  module V1
    class FleetModelsTest < ActionController::TestCase
      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s
      end

      tests Gql::V1::BaseController

      let(:data) { users :data }
      let(:enterprise) { user_ships :enterprise }
      let(:query) do
        %|query ($sid: String!) {
          fleetModels(sid: $sid) {
            count
            model {
              name
            }
          }
        }|
      end
      let(:variables) do
        {
          sid: 'tmi'
        }
      end

      before do
        enterprise
      end

      describe 'with unauthorized user' do
        let(:will) { users :will }

        before do
          add_authorization will
        end

        test "#counts" do
          post :execute, params: { query: query, variables: variables }

          expectation = { 'code' => 'not_found', 'message' => 'No Entry found' }

          assert_equal expectation, JSON.parse(response.body)
        end
      end

      describe 'with authorized user' do
        before do
          add_authorization data
        end

        test "#counts" do
          post :execute, params: { query: query, variables: variables }

          expectation = {
            'data' => {
              'fleetModels' => [
                {
                  'count' => 1,
                  'model' => {
                    'name' => 'Andromeda'
                  }
                }
              ]
            }
          }

          assert_equal expectation, JSON.parse(response.body)
        end
      end
    end
  end
end
