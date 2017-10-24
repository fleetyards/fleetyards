# frozen_string_literal: true

require "test_helper"

module Gql
  module V1
    class AcceptFleetJoinTest < ActionController::TestCase
      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s
      end

      tests Gql::V1::BaseController

      let(:query) do
        %|mutation (
          $sid: String!,
          $username: String!
        ) {
          acceptFleetJoin(
            sid: $sid,
            username: $username
          )
        }|
      end
      let(:variables) do
        {
          sid: 'tmi',
          username: 'troi'
        }
      end

      describe 'without session' do
        test "#returns error" do
          post :execute, params: { query: query, variables: variables }

          expectation = { 'errors' => [{ 'message' => 'Field needs Authentication' }] }

          assert_equal expectation, JSON.parse(response.body)
        end
      end

      describe 'with no member session' do
        let(:will) { users :will }

        before do
          add_authorization will
        end

        test "#failure" do
          post :execute, params: { query: query, variables: variables }

          expectation = { 'code' => 'not_found', 'message' => 'No Entry found' }

          assert_equal expectation, JSON.parse(response.body)
        end
      end

      describe 'with normal member session' do
        let(:worf) { users :worf }

        before do
          add_authorization worf
        end

        test "#failure" do
          post :execute, params: { query: query, variables: variables }

          expectation = { 'code' => 'not_found', 'message' => 'No Entry found' }

          assert_equal expectation, JSON.parse(response.body)
        end
      end

      describe 'with admin member session' do
        let(:data) { users :data }
        let(:troi) { users :troi }

        before do
          add_authorization data
        end

        test "#success" do
          post :execute, params: { query: query, variables: variables }

          expectation = {
            'data' => {
              'acceptFleetJoin' => true
            }
          }

          assert_equal expectation, JSON.parse(response.body)
          assert_equal 1, FleetMembership.where(user_id: troi.id, approved: true).count
        end
      end
    end
  end
end
