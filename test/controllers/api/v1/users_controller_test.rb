# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class UsersControllerTest < ActionController::TestCase
      tests Api::V1::UsersController

      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s

        @data = users :data
      end

      test 'should render 401 for destroy' do
        get :destroy

        assert_response :unauthorized

        json = JSON.parse response.body

        assert_equal 'unauthorized', json['code']
      end

      test 'should delete the current user' do
        sign_in @data

        delete :destroy

        assert_response :ok

        assert_nil User.find_by(id: @data.id)
      end
    end
  end
end
