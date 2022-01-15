# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class RoadmapControllerTest < ActionController::TestCase
      tests Api::V1::RoadmapController

      def setup
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s
      end

      test 'should return list for index' do
        get :index

        assert_response :ok

        json = JSON.parse response.body
        result = json.map { |item| item['id'] }

        expectation = RoadmapItem.order('rsi_category_id asc', 'name asc').pluck(:id)

        assert_equal expectation, result
      end

      test 'with session should return list for index' do
        sign_in(users(:data))

        get :index

        assert_response :ok

        json = JSON.parse response.body
        result = json.map { |item| item['id'] }

        expectation = RoadmapItem.order('rsi_category_id asc', 'name asc').pluck(:id)

        assert_equal expectation, result
      end
    end
  end
end
