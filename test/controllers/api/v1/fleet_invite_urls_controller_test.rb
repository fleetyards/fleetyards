# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class FleetInviteUrlsControllerTest < ActionController::TestCase
      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s
      end

      tests Api::V1::FleetInviteUrlsController

      let(:starfleet) { fleets :starfleet }
      let(:fleet_invite_url) { fleet_invite_urls :one }

      describe 'without session' do
        test 'should render 401 for index' do
          get :index, params: { fleet_slug: starfleet.slug }

          assert_response :unauthorized
          json = JSON.parse response.body
          assert_equal 'unauthorized', json['code']
        end

        test 'should render 401 for exists' do
          get :exists, params: { fleet_slug: starfleet.slug, token: fleet_invite_url.token }

          assert_response :unauthorized
          json = JSON.parse response.body
          assert_equal 'unauthorized', json['code']
        end

        test 'should render 401 for show' do
          get :show, params: { fleet_slug: starfleet.slug, token: fleet_invite_url.token }

          assert_response :unauthorized
          json = JSON.parse response.body
          assert_equal 'unauthorized', json['code']
        end

        test 'should render 401 for create' do
          post :create, params: { fleet_slug: starfleet.slug }

          assert_response :unauthorized
          json = JSON.parse response.body
          assert_equal 'unauthorized', json['code']
        end

        test 'should render 401 for destroy' do
          delete :destroy, params: { fleet_slug: starfleet.slug, token: fleet_invite_url.token }

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
                'inviteCount' => fleet_invite_url.invite_count,
                'url' => fleet_invite_url.url,
                'createdAt' => fleet_invite_url.created_at.utc.iso8601,
                'updatedAt' => fleet_invite_url.updated_at.utc.iso8601
              }
            ]
          end

          test 'should return list for index' do
            get :index, params: { fleet_slug: starfleet.slug }

            assert_response :ok

            json = JSON.parse response.body

            assert_equal expected, json
          end
        end

        test 'should render ok for exists' do
          get :exists, params: { fleet_slug: starfleet.slug, token: fleet_invite_url.token }

          assert_response :ok
        end

        test 'should render 403 for show' do
          post :create, params: { fleet_slug: starfleet.slug, token: fleet_invite_url.token }

          assert_response :forbidden
          json = JSON.parse response.body
          assert_equal 'forbidden', json['code']
        end

        test 'should render 403 for create' do
          post :create, params: { fleet_slug: starfleet.slug }

          assert_response :forbidden
          json = JSON.parse response.body
          assert_equal 'forbidden', json['code']
        end

        test 'should render 403 for destroy' do
          delete :destroy, params: { fleet_slug: starfleet.slug, token: fleet_invite_url.token }

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
                'inviteCount' => fleet_invite_url.invite_count,
                'url' => fleet_invite_url.url,
                'createdAt' => fleet_invite_url.created_at.utc.iso8601,
                'updatedAt' => fleet_invite_url.updated_at.utc.iso8601
              }
            ]
          end

          test 'should return list for index' do
            get :index, params: { fleet_slug: starfleet.slug }

            assert_response :ok

            json = JSON.parse response.body

            assert_equal expected, json
          end
        end

        test 'should render ok for exists' do
          get :exists, params: { fleet_slug: starfleet.slug, token: fleet_invite_url.token }

          assert_response :ok
        end

        describe '#show' do
          let(:expected) do
            {
              'token' => fleet_invite_url.token,
              'inviteCount' => fleet_invite_url.invite_count,
              'url' => fleet_invite_url.url,
              'createdAt' => fleet_invite_url.created_at.utc.iso8601,
              'updatedAt' => fleet_invite_url.updated_at.utc.iso8601
            }
          end

          test 'should return list for index' do
            get :show, params: { fleet_slug: starfleet.slug, token: fleet_invite_url.token }

            assert_response :ok

            json = JSON.parse response.body

            assert_equal expected, json
          end
        end

        describe '#create' do
          test 'should return list for index' do
            post :create, params: { fleet_slug: starfleet.slug }

            assert_response :ok

            json = JSON.parse response.body

            assert(json.present?)
          end
        end

        describe '#destroy' do
          test 'should return list for index' do
            delete :destroy, params: { fleet_slug: starfleet.slug, token: fleet_invite_url.token }

            assert_response :ok
          end
        end
      end
    end
  end
end
