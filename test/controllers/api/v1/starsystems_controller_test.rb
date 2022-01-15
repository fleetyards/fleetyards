# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class StarsystemsControllerTest < ActionController::TestCase
      tests Api::V1::StarsystemsController

      def setup
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s

        @data = users :data
      end

      test 'should return list for index' do
        stanton = starsystems :stanton
        oberon = starsystems :oberon

        get :index

        assert_response :ok

        json = JSON.parse response.body
        result = json.map { |item| item['name'] }

        assert_equal [oberon.name, stanton.name], result
      end

      test 'should return a single record for show' do
        stanton = starsystems :stanton

        get :show, params: { slug: stanton.slug }

        assert_response :ok

        json = JSON.parse response.body

        assert_equal stanton.name, json['name']
      end

      test 'with session should return list for index' do
        sign_in(@data)

        stanton = starsystems :stanton
        oberon = starsystems :oberon

        get :index

        assert_response :ok

        json = JSON.parse response.body
        result = json.map { |item| item['name'] }

        assert_equal [oberon.name, stanton.name], result
      end

      test 'with session should return a single record for show' do
        sign_in(@data)

        stanton = starsystems :stanton

        get :show, params: { slug: stanton.slug }

        assert_response :ok

        json = JSON.parse response.body

        assert_equal stanton.name, json['name']
      end
    end
  end
end
