# frozen_string_literal: true

require 'test_helper'

module Admin
  class ModelsControllerTest < ActionController::TestCase
    tests Admin::ModelsController

    test 'should redirect to login for index' do
      get :index

      assert_redirected_to new_admin_user_session_url
    end
    # test 'should render not_found for show'
    # test 'should render not_found for new'
    # test 'should render not_found for create'
    # test 'should render not_found for edit'
    # test 'should render not_found for update'
    # test 'should render not_found for destroy'

    class ModelsControllerWithSessionTest < ActionController::TestCase
      setup do
        @data = users(:data)
        sign_in(@data)
      end

      test 'should redirect to login for index' do
        get :index

        assert_redirected_to new_admin_user_session_url
      end
      # test 'should render not_found for show'
      # test 'should render not_found for new'
      # test 'should render not_found for create'
      # test 'should render not_found for edit'
      # test 'should render not_found for update'
      # test 'should render not_found for destroy'
    end

    class ModelsControllerWithAdminSessionTest < ActionController::TestCase
      setup do
        @jeanluc = admin_users(:jeanluc)
        sign_in(@jeanluc)
      end

      # test 'should render index'
      # test 'should render show'
      # test 'should render new'
      # test 'should create new model'
      # test 'should render edit'
      # test 'should update model'
      # test 'should destroy model'
    end
  end
end
