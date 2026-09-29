# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

class UserRsiOrganizationsTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @user.verify_rsi_handle("TestPilot", via: :rsi_profile)
    @user.save!
    @fleet = create(:fleet, rsi_sid: "MAIN", members: [@user])
  end

  def stub_page(status: 200, main: "MAIN")
    body = format(Rails.root.join("test/fixtures/rsi/citizen_organizations_page.html").read, main:, affiliation: "WING", redacted: "SECRET")
    stub_request(:get, "https://robertsspaceindustries.com/en/citizens/TestPilot/organizations").to_return(status:, body:)
  end

  def membership
    @fleet.fleet_memberships.find_by(user: @user)
  end

  test "the visible orgs on the page become the user's list and verify the memberships" do
    stub_page

    assert_equal :ok, UserRsiOrganizations.new(@user).run

    @user.reload
    assert_equal %w[MAIN WING], @user.rsi_organization_sids
    assert @user.rsi_organizations_checked_at.present?
    assert membership.verified?
  end

  test "a failed read leaves the list as it is, and is only counted as an attempt" do
    @user.store_rsi_organizations(%w[MAIN], read_at: 1.day.ago)
    stub_page(status: 500)

    assert_equal :failed, UserRsiOrganizations.new(@user).run

    @user.reload
    assert_equal %w[MAIN], @user.rsi_organization_sids
    assert @user.rsi_organizations_checked_at < 1.hour.ago
    assert @user.rsi_organizations_attempted_at > 1.minute.ago
    assert membership.verified?
  end

  test "a block is not counted as an attempt, so the user stays due" do
    stub_page(status: 403)

    assert_equal :blocked, UserRsiOrganizations.new(@user).run
    assert_nil @user.reload.rsi_organizations_attempted_at
  end

  test "an answer for a handle the user has since lost is dropped" do
    stub_page
    check = UserRsiOrganizations.new(@user)
    User.find(@user.id).revoke_rsi_handle_verification!

    assert_equal :stale, check.run
    assert_empty @user.reload.rsi_organization_sids
    assert_not membership.verified?
  end

  test "a user without a verified handle is not read" do
    @user.revoke_rsi_handle_verification!

    assert_equal :skipped, UserRsiOrganizations.new(@user.reload).run
  end
end
