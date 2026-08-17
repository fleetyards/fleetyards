# frozen_string_literal: true

require "test_helper"

class AhoyExcludeMethodTest < ActiveSupport::TestCase
  FakeRequest = Struct.new(:headers)

  class FakeController
    def initialize(current_user = nil)
      @current_user = current_user
    end

    attr_reader :current_user
  end

  def exclude?(user: nil, headers: {})
    Ahoy.exclude_method.call(FakeController.new(user), FakeRequest.new(headers))
  end

  test "tracks a signed-in user who has not objected" do
    assert_not exclude?(user: build(:user, tracking: true))
  end

  test "tracks an anonymous visitor by default" do
    assert_not exclude?
  end

  test "excludes a signed-in user who has objected" do
    assert exclude?(user: build(:user, tracking: false))
  end

  test "excludes any visitor sending Global Privacy Control" do
    assert exclude?(headers: {"Sec-GPC" => "1"})
  end

  test "excludes a signed-in user sending Global Privacy Control" do
    assert exclude?(user: build(:user, tracking: true), headers: {"Sec-GPC" => "1"})
  end

  test "ignores an unset Global Privacy Control header" do
    assert_not exclude?(headers: {"Sec-GPC" => "0"})
  end

  test "tracks when there is no controller" do
    assert_not Ahoy.exclude_method.call(nil, FakeRequest.new({}))
  end

  test "tracks when there is no request" do
    assert_not Ahoy.exclude_method.call(FakeController.new, nil)
  end
end
