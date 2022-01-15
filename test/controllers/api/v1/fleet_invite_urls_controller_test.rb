# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class FleetInviteUrlsControllerTest < ActionController::TestCase
      tests Api::V1::FleetInviteUrlsController

      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s

        @starfleet = fleets(:starfleet)
        @fleet_invite_url = fleet_invite_urls(:one)

        @data = users(:data)
        @jeanluc = users(:jeanluc)
      end

      test 'should render 401 for index' do
        get :index, params: { fleet_slug: @starfleet.slug }

        assert_response :unauthorized

        json = JSON.parse response.body

        assert_equal 'unauthorized', json['code']
      end

      test 'should render 401 for create' do
        post :create, params: { fleet_slug: @starfleet.slug }

        assert_response :unauthorized

        json = JSON.parse response.body

        assert_equal 'unauthorized', json['code']
      end

      test 'should render 401 for destroy' do
        delete :destroy, params: { fleet_slug: @starfleet.slug, token: @fleet_invite_url.token }

        assert_response :unauthorized

        json = JSON.parse response.body

        assert_equal 'unauthorized', json['code']
      end

      test 'with session should return list for index' do
        sign_in(@data)

        get :index, params: { fleet_slug: @starfleet.slug }

        assert_response :ok

        json = JSON.parse response.body

        assert_equal @fleet_invite_url.token, json.first['token']
      end

      test 'with session should render 403 for create' do
        sign_in(@data)

        post :create, params: { fleet_slug: @starfleet.slug }

        assert_response :forbidden

        json = JSON.parse response.body

        assert_equal 'forbidden', json['code']
      end

      test 'with session should render 403 for destroy' do
        sign_in(@data)

        delete :destroy, params: { fleet_slug: @starfleet.slug, token: @fleet_invite_url.token }

        assert_response :forbidden

        json = JSON.parse response.body

        assert_equal 'forbidden', json['code']
      end

      test 'with admin session should return list for index' do
        sign_in(@jeanluc)

        get :index, params: { fleet_slug: @starfleet.slug }

        assert_response :ok

        json = JSON.parse response.body

        assert_equal @fleet_invite_url.token, json.first['token']
      end

      test 'with admin session should create new invite url' do
        sign_in(@jeanluc)

        post :create, params: { fleet_slug: @starfleet.slug }

        assert_response :ok

        json = JSON.parse response.body

        assert(json.present?)
      end

      test 'with admin session should destroy given invite url' do
        sign_in(@jeanluc)

        delete :destroy, params: { fleet_slug: @starfleet.slug, token: @fleet_invite_url.token }

        assert_response :ok
      end
    end
  end
end
