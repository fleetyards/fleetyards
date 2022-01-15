# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class StationsControllerTest < ActionController::TestCase
      tests Api::V1::StationsController

      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s

        @data = users :data
      end

      test 'should return list for index' do
        get :index

        assert_response :ok

        json = JSON.parse response.body
        result = json.map { |item| item['name'] }

        expectation = Station.visible.order(name: :asc).pluck(:name)

        assert_equal expectation, result
      end

      test 'should return a single record for show' do
        portolisar = stations :portolisar

        get :show, params: { slug: portolisar.slug }

        assert_response :ok

        json = JSON.parse response.body

        assert_equal portolisar.name, json['name']
      end

      test 'with session should return list for index' do
        sign_in(@data)

        get :index

        assert_response :ok

        json = JSON.parse response.body
        result = json.map { |item| item['name'] }

        expectation = Station.visible.order(name: :asc).pluck(:name)

        assert_equal expectation, result
      end

      test 'with session should return a single record for show' do
        portolisar = stations :portolisar

        sign_in(@data)

        get :show, params: { slug: portolisar.slug }

        assert_response :ok

        json = JSON.parse response.body

        assert_equal portolisar.name, json['name']
      end
    end
  end
end
