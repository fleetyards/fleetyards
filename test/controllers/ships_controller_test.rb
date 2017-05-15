# frozen_string_literal: true

require "test_helper"

class ShipsControllerTest < ActionController::TestCase
  tests ::ShipsController

  let(:data) { users :data }

  describe "without session" do
    it "should render list of ships"
    it "should render ship detail page"
  end

  describe "with session" do
    before do
      sign_in data
    end

    it "should render list of ships"
    it "should render ship detail page"
  end
end
