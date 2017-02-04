# frozen_string_literal: true
module Backend
  class ShipsControllerTest < ActionController::TestCase
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
      it "should render not_found for index"
      it "should render not_found for show"
      it "should render not_found for new"
      it "should render not_found for create"
      it "should render not_found for edit"
      it "should render not_found for update"
      it "should render not_found for destroy"
    end

    describe "with admin session" do
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
