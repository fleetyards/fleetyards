# frozen_string_literal: true

require "test_helper"

module Admin
  class ShipsControllerTest < ActionController::TestCase
    tests Admin::ShipsController

    let(:data) { users :data }
    let(:jeanluc) { users :jeanluc }

    describe "without session" do
      it "should render not_found for index"
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

      it "should render not_found for index"
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
      it "should create new ship"
      it "should render edit"
      it "should update ship"
      it "should destroy ship"
    end
  end
end
