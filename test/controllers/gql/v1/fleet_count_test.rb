# frozen_string_literal: true

# frozen_string_literal: true

require "test_helper"

module Gql
  module V1
    class FleetCountTest < ActionController::TestCase
      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s
      end

      tests Gql::V1::BaseController

      let(:data) { users :data }
      let(:enterprise) { user_ships :enterprise }
      let(:query) do
        %|query ($sid: String!) {
          fleetCount(sid: $sid) {
            total
            classifications {
              count
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
              'fleetCount' => {
                'total' => 1,
                'classifications' => [
                  {
                    'count' => 1,
                    'name' => 'multi_role'
                  }
                ]
              }
            }
          }

          assert_equal expectation, JSON.parse(response.body)
        end
      end
    end
  end
end
