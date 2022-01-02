# frozen_string_literal: true

require 'test_helper'

module Admin
  class ShopsControllerTest < ActionController::TestCase
    tests Admin::ShopsController

    let(:data) { users :data }
    let(:jeanluc) { admin_users :jeanluc }

    describe 'without session' do
      it 'should redirect to login for index' do
        get :index

        assert_redirected_to new_admin_user_session_url
      end
    end

    describe 'with session' do
      before do
        sign_in data
      end

      it 'should redirect to login for index' do
        get :index

        assert_redirected_to new_admin_user_session_url
      end
    end

    describe 'with admin session' do
      before do
        sign_in jeanluc
      end

      it 'should render index'
    end
  end
end
