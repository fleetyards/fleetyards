# frozen_string_literal: true

require 'test_helper'

module Admin
  class ShopsControllerTest < ActionController::TestCase
    tests Admin::ShopsController

    test 'should redirect to login for index' do
      get :index

      assert_redirected_to new_admin_user_session_url
    end

    class ShopsControllerWithSessionTest < ActionController::TestCase
      setup do
        @data = users(:data)
        sign_in(@data)
      end

      test 'should redirect to login for index' do
        get :index

        assert_redirected_to new_admin_user_session_url
      end
    end

    class ShopsControllerWithAdminSessionTest < ActionController::TestCase
      setup do
        @jeanluc = admin_users(:jeanluc)
        sign_in(@jeanluc)
      end

      # test 'should render index'
    end
  end
end
