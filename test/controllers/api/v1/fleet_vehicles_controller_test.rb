# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class FleetVehiclesControllerTest < ActionController::TestCase
      tests Api::V1::FleetVehiclesController

      def setup
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s

        @starfleet = fleets :starfleet
        @data = users :data
      end

      test 'should render 403 for index' do
        get :index, params: { slug: @starfleet.slug }

        assert_response :unauthorized

        json = JSON.parse response.body

        assert_equal 'unauthorized', json['code']
      end

      test 'should render 403 for quick-stats' do
        get :quick_stats, params: { slug: @starfleet.slug }

        assert_response :unauthorized

        json = JSON.parse response.body

        assert_equal 'unauthorized', json['code']
      end

      test 'should render 403 for fleetchart' do
        get :fleetchart, params: { slug: @starfleet.slug }

        assert_response :unauthorized

        json = JSON.parse response.body

        assert_equal 'unauthorized', json['code']
      end

      test 'should render 200 for public' do
        get :public, params: { slug: @starfleet.slug }

        assert_response :ok
      end

      test 'should render 200 for public-fleetchart' do
        get :public_fleetchart, params: { slug: @starfleet.slug }

        assert_response :ok
      end

      test 'should return list for index' do
        sign_in(@data)

        get :index, params: { slug: @starfleet.slug }

        assert_response :ok
        json = JSON.parse response.body
        data = json.map { |item| item['model']['name'] }

        assert_equal(%w[600i Andromeda], data)
      end

      test 'should return list with loaners for index' do
        sign_in(@data)

        get :index, params: { slug: @starfleet.slug, q: { loanerEq: true } }

        assert_response :ok
        json = JSON.parse response.body
        data = json.map { |item| item['model']['name'] }

        assert_equal(%w[600i Andromeda PTV], data)
      end

      test 'should return list with only loaners for index' do
        sign_in(@data)

        get :index, params: { slug: @starfleet.slug, q: { loanerEq: 'only' } }

        assert_response :ok
        json = JSON.parse response.body
        data = json.map { |item| item['model']['name'] }

        assert_equal(%w[PTV], data)
      end

      test 'should return grouped list for index' do
        sign_in(@data)

        get :index, params: { slug: @starfleet.slug, grouped: true }

        assert_response :ok

        json = JSON.parse response.body
        data = json.map { |item| item['name'] }

        assert_equal(%w[600i Andromeda], data)
      end

      test 'should return grouped list with loaners for index' do
        sign_in(@data)

        get :index, params: { slug: @starfleet.slug, grouped: true, q: { loanerEq: true } }

        assert_response :ok

        json = JSON.parse response.body
        data = json.map { |item| item['name'] }

        assert_equal(%w[600i Andromeda PTV], data)
      end

      test 'should return grouped list with only loaners for index' do
        sign_in(@data)

        get :index, params: { slug: @starfleet.slug, grouped: true, q: { loanerEq: 'only' } }

        assert_response :ok

        json = JSON.parse response.body
        data = json.map { |item| item['name'] }

        assert_equal(%w[PTV], data)
      end
    end
  end
end
