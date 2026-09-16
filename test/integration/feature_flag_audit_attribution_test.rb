# frozen_string_literal: true

require "test_helper"
require "support/flipper_audit_test_helpers"

# Which surface a flag change is credited to. The subscriber itself is covered by
# FeatureFlags::AuditSubscriberTest; what these pin down is that a real request
# through each writing path arrives with FeatureFlags::Current already set.
class FeatureFlagAuditAttributionTest < ActionDispatch::IntegrationTest
  setup do
    FeatureFlagChange.delete_all
  end

  test "an admin toggle is credited to the admin who made it" do
    admin = create(:admin_user, resource_access: [:features])

    with_flag_auditing do
      Flipper.add("TestFeature")
      sign_in admin

      put "/admin/api/v1/features/TestFeature/enable"

      assert_response :success
    end

    change = FeatureFlagChange.for_feature("TestFeature").find_by(operation: "enable")

    assert_equal FeatureFlagChange::SOURCE_ADMIN, change.source
    assert_equal admin, change.admin_user
    assert_nil change.user
  end

  test "a user switching a feature on for themselves is credited as self-service" do
    user = create(:user)
    FeatureSetting.create!(feature_name: "TestFeature", self_service_user: true)

    with_flag_auditing do
      Flipper.add("TestFeature")
      sign_in user

      put "/api/v1/user-features/TestFeature/enable"

      assert_response :success
    end

    change = FeatureFlagChange.for_feature("TestFeature").find_by(operation: "enable")

    assert_equal FeatureFlagChange::SOURCE_SELF_SERVICE, change.source
    assert_equal user, change.user
    assert_nil change.admin_user
    assert_equal FeatureFlagChange::STATE_CONDITIONAL, change.state_after
  end

  test "a fleet toggle is credited to the member who made it" do
    user = create(:user)
    fleet = create(:fleet, admins: [user])
    FeatureSetting.create!(feature_name: "TestFeature", self_service_fleet: true)

    with_flag_auditing do
      Flipper.add("TestFeature")
      sign_in user

      put "/api/v1/fleets/#{fleet.slug}/features/TestFeature/enable"

      assert_response :success
    end

    change = FeatureFlagChange.for_feature("TestFeature").find_by(operation: "enable")

    assert_equal FeatureFlagChange::SOURCE_SELF_SERVICE, change.source
    assert_equal user, change.user
    assert_equal fleet.flipper_id, change.thing
  end
end
