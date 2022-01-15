# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class CelestialObjectsControllerTest < ActionController::TestCase
      tests Api::V1::CelestialObjectsController

      test 'should return list for index' do
        get :index

        assert_response :ok

        json = JSON.parse response.body
        result = json.map { |item| item['slug'] }

        expectation = CelestialObject.visible.order('parent_id desc', 'designation asc').pluck(:slug)

        assert_equal expectation, result
      end

      test 'should return a single record for show' do
        crusader = celestial_objects(:crusader)

        get :show, params: { slug: crusader.slug }

        assert_response :ok

        json = JSON.parse response.body

        assert_equal crusader.name, json['name']
      end

      test 'with session should return list for index' do
        data = users(:data)

        sign_in(data)

        get :index

        assert_response :ok

        json = JSON.parse response.body
        result = json.map { |item| item['slug'] }

        expectation = CelestialObject.visible.order('parent_id desc', 'designation asc').pluck(:slug)

        assert_equal expectation, result
      end

      test 'with session should return a single record for show' do
        data = users(:data)
        crusader = celestial_objects(:crusader)

        sign_in(data)

        get :show, params: { slug: crusader.slug }

        assert_response :ok

        json = JSON.parse response.body

        assert_equal crusader.name, json['name']
      end
    end
  end
end
