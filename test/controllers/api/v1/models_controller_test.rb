# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class ModelsControllerTest < ActionController::TestCase
      tests Api::V1::ModelsController

      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s

        @origin600i = Model.find_by(slug: '600i')
      end

      test 'should return list for index' do
        get :index

        assert_response :ok

        json = JSON.parse response.body
        result = json.map { |item| item['name'] }

        assert_equal [@origin600i.name, Model.last.name], result
      end

      test 'should be able to filter the list' do
        get :index, params: { q: '{ "nameCont": "Andromeda" }' }

        assert_response :ok

        json = JSON.parse response.body

        assert_equal 1, json.count
        assert_equal 'Andromeda', json.first['name']
      end

      test 'should be able to reduce per page size' do
        get :index, params: { perPage: '15' }

        assert_response :ok

        json = JSON.parse response.body

        # result count is 2 because there are only 2 models in the database
        assert_equal 2, json.count
      end

      test 'should return detail' do
        get :show, params: { slug: @origin600i.slug }

        assert_response :ok

        json = JSON.parse response.body

        assert_equal @origin600i.name, json['name']
      end
    end
  end
end
