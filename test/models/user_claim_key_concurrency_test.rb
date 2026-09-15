# frozen_string_literal: true

require "test_helper"

# Two requests arriving at once. Without the row lock both find no key, both
# generate one, and the loser is handed a value that stopped existing before
# they could copy it out of the page.
class UserClaimKeyConcurrencyTest < ActiveSupport::TestCase
  # Threads need real connections, so the wrapping transaction has to go.
  self.use_transactional_tests = false

  setup do
    @user = create(:user)
  end

  # No wrapping transaction to roll back, so this cleans up after itself.
  teardown do
    User.where(id: @user.id).destroy_all
  end

  # Both records are loaded *before* either thread runs, which is what a pair of
  # concurrent requests actually holds: two instances that each read no key.
  # Loading inside the thread would let the second pick up the first's write and
  # the race would never happen.
  test "two creations settle on one key" do
    handed_out = Queue.new
    holders = [User.find(@user.id), User.find(@user.id)]

    holders.map do |holder|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          handed_out << holder.ensure_claim_key!
        end
      end
    end.each(&:join)

    keys = []
    keys << handed_out.pop until handed_out.empty?

    assert_equal 2, keys.size
    assert_equal 1, keys.uniq.size, "both callers must be handed the same key"
    assert_equal @user.reload.claim_key, keys.first
  end
end
