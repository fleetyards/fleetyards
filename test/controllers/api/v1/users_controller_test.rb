# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class UsersControllerTest < ActionController::TestCase
      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s
      end

      tests Api::V1::UsersController

      describe 'without session' do
        it 'should render 401 for destroy' do
          get :destroy

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

        it 'should delete the current user' do
          get :destroy

          assert_response :ok

          assert_nil User.find_by(id: data.id)
        end
      end
    end
  end
end
