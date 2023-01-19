# frozen_string_literal: true

require "test_helper"

module Admin
  class ModelsControllerTest < ActionDispatch::IntegrationTest
    let(:data) { users :data }
    let(:jeanluc) { admin_users :jeanluc }

    describe "without session" do
      it "should redirect to login for index" do
        get "/admin/models"

        assert_redirected_to new_admin_user_session_url
      end
      it "should render not_found for show"
      it "should render not_found for new"
      it "should render not_found for create"
      it "should render not_found for edit"
      it "should render not_found for update"
      it "should render not_found for destroy"
    end

    describe "with session" do
      before do
        sign_in data
      end

      it "should redirect to login for index" do
        get "/admin/models"

        assert_redirected_to new_admin_user_session_url
      end
      it "should render not_found for show"
      it "should render not_found for new"
      it "should render not_found for create"
      it "should render not_found for edit"
      it "should render not_found for update"
      it "should render not_found for destroy"
    end

    describe "with admin session" do
      before do
        sign_in jeanluc
      end

      it "should render index"
      it "should render show"
      it "should render new"
      it "should create new model"
      it "should render edit"
      it "should update model"
      it "should destroy model"
    end
  end
end
