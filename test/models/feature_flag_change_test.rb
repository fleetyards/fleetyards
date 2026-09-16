# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: feature_flag_changes
#
#  id            :uuid             not null, primary key
#  feature_name  :string           not null
#  gate_name     :string
#  operation     :string           not null
#  source        :string           not null
#  state_after   :string           not null
#  thing         :string
#  created_at    :datetime         not null
#  admin_user_id :uuid
#  user_id       :uuid
#
# Indexes
#
#  index_feature_flag_changes_on_admin_user_id                (admin_user_id)
#  index_feature_flag_changes_on_feature_name_and_created_at  (feature_name,created_at DESC)
#  index_feature_flag_changes_on_user_id                      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (admin_user_id => admin_users.id) ON DELETE => nullify
#  fk_rails_...  (user_id => users.id) ON DELETE => nullify
#
class FeatureFlagChangeTest < ActiveSupport::TestCase
  setup do
    FeatureFlagChange.delete_all
  end

  def change_at(time, state, feature_name: "audited")
    FeatureFlagChange.create!(
      feature_name: feature_name,
      operation: "enable",
      state_after: state,
      source: FeatureFlagChange::SOURCE_CONSOLE,
      created_at: time
    )
  end

  test "fully_on_since is nil for a flag with no history" do
    assert_nil FeatureFlagChange.fully_on_since("audited")
  end

  test "fully_on_since is nil while the flag is not on" do
    change_at(3.days.ago, FeatureFlagChange::STATE_ON)
    change_at(1.day.ago, FeatureFlagChange::STATE_CONDITIONAL)

    assert_nil FeatureFlagChange.fully_on_since("audited")
  end

  # Granting an extra actor to an already-open flag writes a second `on` row,
  # and the flag has been open since the first of them.
  test "fully_on_since is the start of the current run, not its newest row" do
    opened = 5.days.ago
    change_at(opened, FeatureFlagChange::STATE_ON)
    change_at(2.days.ago, FeatureFlagChange::STATE_ON)

    assert_in_delta opened, FeatureFlagChange.fully_on_since("audited"), 1.second
  end

  # The case flipper_gates gets wrong: a disable deletes the gate row, so a
  # re-enable looks like the flag was never off.
  test "fully_on_since restarts after the flag is switched off" do
    reopened = 1.day.ago
    change_at(10.days.ago, FeatureFlagChange::STATE_ON)
    change_at(4.days.ago, FeatureFlagChange::STATE_OFF)
    change_at(reopened, FeatureFlagChange::STATE_ON)

    assert_in_delta reopened, FeatureFlagChange.fully_on_since("audited"), 1.second
  end

  test "fully_on_since ignores other flags" do
    change_at(5.days.ago, FeatureFlagChange::STATE_ON, feature_name: "other")

    assert_nil FeatureFlagChange.fully_on_since("audited")
  end

  test "fully_on_since accepts a symbol" do
    change_at(5.days.ago, FeatureFlagChange::STATE_ON)

    assert_not_nil FeatureFlagChange.fully_on_since(:audited)
  end

  test "operation, state and source are constrained" do
    change = FeatureFlagChange.new(feature_name: "audited", operation: "enabled?", state_after: "sideways", source: "guesswork")

    assert_not change.valid?
    assert_includes change.errors.attribute_names, :operation
    assert_includes change.errors.attribute_names, :state_after
    assert_includes change.errors.attribute_names, :source
  end
end
