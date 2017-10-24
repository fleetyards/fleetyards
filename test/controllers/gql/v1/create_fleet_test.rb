# frozen_string_literal: true

require "test_helper"

module Gql
  module V1
    class CreateFleetTest < ActionController::TestCase
      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s
      end

      tests Gql::V1::BaseController

      let(:will) { users :will }
      let(:query) do
        %|mutation ($sid: String!) {
          createFleet(sid: $sid) {
            name
            sid
            logo
            members {
              username
            }
          }
        }|
      end

      before do
        add_authorization will
      end

      describe 'with taken sid' do
        let(:variables) do
          {
            sid: 'tmi'
          }
        end

        test "#returns error" do
          post :execute, params: { query: query, variables: variables }

          expectation = {
            'data' => {
              'createFleet' => nil
            },
            'errors' => [
              {
                'message' => 'Sid has already been taken',
                'locations' => [
                  {
                    'line' => 2,
                    'column' => 11
                  }
                ],
                'path' => 'create.sid'
              }
            ]
          }

          assert_equal expectation, JSON.parse(response.body)
        end
      end

      describe 'with valid sid' do
        let(:variables) do
          {
            sid: 'merccorp'
          }
        end

        test "#success" do
          VCR.use_cassette('create_fleet_merc') do
            post :execute, params: { query: query, variables: variables }

            expectation = {
              'data' => {
                'createFleet' => {
                  'name' => 'M.E.R.C. Corporation',
                  'sid' => 'merccorp',
                  'logo' => 'https://robertsspaceindustries.com/media/p7e22y3wa5wv2r/logo/MERCCORP-Logo.png',
                  'members' => [
                    {
                      'username' => 'willriker'
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
end
