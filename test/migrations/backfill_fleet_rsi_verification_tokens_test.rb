# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20260929090000_backfill_fleet_rsi_verification_tokens.rb")

class BackfillFleetRsiVerificationTokensTest < ActiveSupport::TestCase
  test "every fleet without a token gets its own" do
    fleets = create_list(:fleet, 2, created_by: create(:user).id)
    Fleet.where(id: fleets.map(&:id)).update_all(rsi_verification_token: nil) # rubocop:disable Rails/SkipsModelValidations

    BackfillFleetRsiVerificationTokens.new.up

    tokens = fleets.map { |fleet| fleet.reload.rsi_verification_token }
    assert tokens.all?(&:present?)
    assert_equal 2, tokens.uniq.size
  end

  test "a fleet's existing token is kept" do
    fleet = create(:fleet, created_by: create(:user).id)
    token = fleet.rsi_verification_token

    BackfillFleetRsiVerificationTokens.new.up

    assert_equal token, fleet.reload.rsi_verification_token
  end
end
