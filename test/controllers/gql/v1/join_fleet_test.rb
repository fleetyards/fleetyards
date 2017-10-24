# frozen_string_literal: true

require "test_helper"

module Gql
  module V1
    class JoinFleetTest < ActionController::TestCase
      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s
      end

      tests Gql::V1::BaseController

      let(:query) do
        %|mutation ($sid: String!) {
          joinFleet(sid: $sid)
        }|
      end
      let(:variables) do
        {
          sid: 'tmi'
        }
      end

      describe 'without session' do
        test "#returns error" do
          post :execute, params: { query: query, variables: variables }

          expectation = { 'errors' => [{ 'message' => 'Field needs Authentication' }] }

          assert_equal expectation, JSON.parse(response.body)
        end
      end

      describe 'with session' do
        let(:will) { users :will }

        before do
          add_authorization will
        end

        test "#success" do
          VCR.use_cassette('create_fleet_merc') do
            post :execute, params: { query: query, variables: variables }

            expectation = {
              'data' => {
                'joinFleet' => true
              }
            }

            assert_equal expectation, JSON.parse(response.body)
          end
        end
      end
    end
  end
end
