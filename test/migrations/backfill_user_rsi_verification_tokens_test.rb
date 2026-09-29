# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20260929150100_backfill_user_rsi_verification_tokens.rb")

class BackfillUserRsiVerificationTokensTest < ActiveSupport::TestCase
  test "every user without a token gets their own" do
    users = create_list(:user, 2)
    User.where(id: users.map(&:id)).update_all(rsi_verification_token: nil) # rubocop:disable Rails/SkipsModelValidations

    BackfillUserRsiVerificationTokens.new.up

    tokens = users.map { |user| user.reload.rsi_verification_token }
    assert tokens.all?(&:present?)
    assert_equal 2, tokens.uniq.size
  end

  test "a user's existing token is kept" do
    user = create(:user)
    token = user.rsi_verification_token

    BackfillUserRsiVerificationTokens.new.up

    assert_equal token, user.reload.rsi_verification_token
  end
end
