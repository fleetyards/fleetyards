# frozen_string_literal: true

require "test_helper"

# `User.with_feature` reads Flipper's gates as a query, which the transfer
# pickers need: they are searched and paginated in SQL, so a per-row
# `Flipper.enabled?` would filter one page at a time.
class UserFeatureScopesTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @other = create(:user)
  end

  test "admits the actors a feature was switched on for, and nobody else" do
    Flipper.enable_actor("hangar_planner", @user)

    assert_equal [@user.id], User.with_feature(:hangar_planner).pluck(:id)
  end

  test "admits everybody once the feature is on outright" do
    Flipper.enable("hangar_planner")

    assert_includes User.with_feature(:hangar_planner).pluck(:id), @other.id
  end

  test "admits nobody for a feature nothing has switched on" do
    assert_empty User.with_feature(:hangar_planner)
  end

  # `testers` is the one registered group a User can be in, and it is a column.
  test "admits the testers group" do
    @other.update!(tester: true)
    Flipper.enable_group("hangar_planner", :testers)

    assert_equal [@other.id], User.with_feature(:hangar_planner).pluck(:id)
  end

  # Neither percentage rollout can be written as a query. Admitting everybody
  # offers somebody the gate may still refuse, which is the harmless way round;
  # admitting nobody would hide people who can in fact receive.
  test "admits everybody under a percentage rollout it cannot express" do
    Flipper.enable_percentage_of_actors("hangar_planner", 50)

    assert_includes User.with_feature(:hangar_planner).pluck(:id), @other.id
  end

  # `percentage_of_time` answers differently per call rather than per actor, so
  # there is no set of ids it could ever resolve to. Reading only the actor gate
  # would have hidden everybody for the whole rollout.
  test "admits everybody under a time-based rollout too" do
    Flipper.enable_percentage_of_time("hangar_planner", 50)

    assert_includes User.with_feature(:hangar_planner).pluck(:id), @other.id
  end
end
