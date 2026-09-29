# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

class RsiOrganizationsRefreshJobTest < ActiveSupport::TestCase
  setup do
    @fleet = create(:fleet, rsi_sid: "MAIN")
    @fleet.update_columns(rsi_verified_at: Time.current, rsi_verified_sid: "MAIN") # rubocop:disable Rails/SkipsModelValidations
    @previous_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache = @previous_cache
  end

  def verified_member(handle, fleet: @fleet)
    create(:user).tap do |user|
      user.verify_rsi_handle(handle, via: :rsi_profile)
      user.save!
      create(:fleet_membership, :accepted, fleet:, user:)
    end
  end

  def stub_pages(status: 200)
    body = format(Rails.root.join("test/fixtures/rsi/citizen_organizations_page.html").read, main: "MAIN", affiliation: "WING", redacted: "SECRET")
    stub_request(:get, %r{\Ahttps://robertsspaceindustries.com/en/citizens/[^/]+/organizations\z}).to_return(status:, body:)
  end

  test "everybody with a verified handle is eligible, in a fleet or not" do
    member = verified_member("InFleet")
    loner = create(:user).tap do |user|
      user.verify_rsi_handle("Loner", via: :citizenid)
      user.save!
    end
    create(:user, rsi_handle: "NoProof")

    assert_equal [member.id, loner.id].sort, RsiOrganizationsRefreshJob.eligible.pluck(:id).sort
  end

  test "a run reads a 24th of them, the longest unchecked first" do
    members = Array.new(25) { |index| verified_member("Pilot#{index}") }
    members.each_with_index do |member, index|
      member.update_columns(rsi_organizations_attempted_at: (index + 21).hours.ago) # rubocop:disable Rails/SkipsModelValidations
    end
    stub_pages

    RsiOrganizationsRefreshJob.new.perform

    checked = members.select { |member| member.reload.rsi_organizations_attempted_at > 1.minute.ago }
    assert_equal members.last(2).map(&:id).sort, checked.map(&:id).sort
  end

  test "a block pauses the refresh for the rest of the day" do
    2.times { |index| verified_member("Pilot#{index}") }
    48.times { |index| verified_member("Later#{index}").update_columns(rsi_organizations_attempted_at: Time.current) } # rubocop:disable Rails/SkipsModelValidations
    stub_pages(status: 403)

    RsiOrganizationsRefreshJob.new.perform

    assert_requested :get, %r{/organizations\z}, times: 1
    assert Rails.cache.read(RsiOrganizationsRefreshJob::PAUSE_KEY)

    RsiOrganizationsRefreshJob.new.perform

    assert_requested :get, %r{/organizations\z}, times: 1
  end
end
