# frozen_string_literal: true

require "test_helper"

class FeatureFlagActorTest < ActiveSupport::TestCase
  setup do
    Flipper.add("first_feature")
    Flipper.add("second_feature")
  end

  test "destroying a user removes it from every flag it was added to" do
    user = create(:user)
    bystander = create(:user)
    Flipper.enable_actor("first_feature", user)
    Flipper.enable_actor("second_feature", user)
    Flipper.enable_actor("second_feature", bystander)

    user.destroy!

    assert_empty Flipper.feature("first_feature").actors_value
    assert_equal Set[bystander.flipper_id], Flipper.feature("second_feature").actors_value
  end

  test "destroying a fleet removes it from every flag it was added to" do
    fleet = create(:fleet)
    Flipper.enable_actor("first_feature", fleet)

    fleet.destroy!

    assert_empty Flipper.feature("first_feature").actors_value
  end
end
