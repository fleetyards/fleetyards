# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class FleetInviteUrlsControllerTest < ActionDispatch::IntegrationTest
      let(:starfleet) { fleets :starfleet }
      let(:fleet_invite_url) { fleet_invite_urls :one }

      describe 'without session' do
        test 'should render 401 for index' do
          get "/api/v1/fleets/#{starfleet.slug}/invite-urls", as: :json

          assert_response :unauthorized
          json = JSON.parse response.body
          assert_equal 'unauthorized', json['code']
        end

        test 'should render 401 for create' do
          post "/api/v1/fleets/#{starfleet.slug}/invite-urls", as: :json

          assert_response :unauthorized
          json = JSON.parse response.body
          assert_equal 'unauthorized', json['code']
        end

        test 'should render 401 for destroy' do
          delete "/api/v1/fleets/#{starfleet.slug}/invite-urls/#{fleet_invite_url.token}", as: :json

          assert_response :unauthorized
          json = JSON.parse response.body
          assert_equal 'unauthorized', json['code']
        end
      end

      describe 'with session' do
        let(:data) { users :data }

        before do
          sign_in data
        end

        describe '#index' do
          let(:expected) do
            [
              {
                'token' => fleet_invite_url.token,
                'url' => fleet_invite_url.url,
                'expiresAfter' => fleet_invite_url.expires_after&.utc&.iso8601,
                'expiresAfterLabel' => fleet_invite_url.expires_after_label,
                'expired' => fleet_invite_url.expired?,
                'limit' => fleet_invite_url.limit,
                'limitReached' => fleet_invite_url.limit_reached?,
                'createdAt' => fleet_invite_url.created_at.utc.iso8601,
                'updatedAt' => fleet_invite_url.updated_at.utc.iso8601
              }
            ]
          end

          test 'should return list for index' do
            get "/api/v1/fleets/#{starfleet.slug}/invite-urls", as: :json

            assert_response :ok

            json = JSON.parse response.body

            assert_equal expected, json
          end
        end

        test 'should render 403 for create' do
          post "/api/v1/fleets/#{starfleet.slug}/invite-urls", as: :json

          assert_response :forbidden
          json = JSON.parse response.body
          assert_equal 'forbidden', json['code']
        end

        test 'should render 403 for destroy' do
          delete "/api/v1/fleets/#{starfleet.slug}/invite-urls/#{fleet_invite_url.token}", as: :json

          assert_response :forbidden
          json = JSON.parse response.body
          assert_equal 'forbidden', json['code']
        end
      end

      describe 'with admin session' do
        let(:jeanluc) { users :jeanluc }

        before do
          sign_in jeanluc
        end

        describe '#index' do
          let(:expected) do
            [
              {
                'token' => fleet_invite_url.token,
                'url' => fleet_invite_url.url,
                'expiresAfter' => fleet_invite_url.expires_after&.utc&.iso8601,
                'expiresAfterLabel' => fleet_invite_url.expires_after_label,
                'expired' => fleet_invite_url.expired?,
                'limit' => fleet_invite_url.limit,
                'limitReached' => fleet_invite_url.limit_reached?,
                'createdAt' => fleet_invite_url.created_at.utc.iso8601,
                'updatedAt' => fleet_invite_url.updated_at.utc.iso8601
              }
            ]
          end

          test 'should return list for index' do
            get "/api/v1/fleets/#{starfleet.slug}/invite-urls", as: :json

            assert_response :ok

            json = JSON.parse response.body

            assert_equal expected, json
          end
        end

        describe '#create' do
          test 'should return list for index' do
            post "/api/v1/fleets/#{starfleet.slug}/invite-urls", as: :json

            assert_response :ok

            json = JSON.parse response.body

            assert(json.present?)
          end
        end

        describe '#destroy' do
          test 'should return list for index' do
            delete "/api/v1/fleets/#{starfleet.slug}/invite-urls/#{fleet_invite_url.token}", as: :json

            assert_response :ok
          end
        end
      end
    end
  end
end
