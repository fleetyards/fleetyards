# frozen_string_literal: true

require "test_helper"

module Api
  class ShipsControllerTest < ActionController::TestCase
    tests ShipsController

    test "#index" do
      get :index

      assert_response :ok
      # json = JSON.parse(response.body)
      # p json
    end
  end
end
