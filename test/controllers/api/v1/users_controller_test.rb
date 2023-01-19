# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class UsersControllerTest < ActionDispatch::IntegrationTest
      describe "without session" do
        it "should render 401 for destroy" do
          delete "/api/v1/users/current", as: :json

          assert_response :unauthorized
          json = JSON.parse response.body

          assert_equal "unauthorized", json["code"]
        end
      end

      describe "with session" do
        let(:data) { users :data }

        before do
          sign_in data
        end

        it "should delete the current user" do
          delete "/api/v1/users/current", as: :json

          assert_response :ok

          assert_nil User.find_by(id: data.id)
        end
      end
    end
  end
end
