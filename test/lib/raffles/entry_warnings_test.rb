# frozen_string_literal: true

require "test_helper"

module Raffles
  class EntryWarningsTest < ActiveSupport::TestCase
    test "addresses that reach the same inbox match" do
      assert_equal "pilot@gmail.com", EntryWarnings.inbox("Pi.lot+raffle@googlemail.com")
      assert_equal "pilot@example.com", EntryWarnings.inbox("pilot+2@Example.com")
      assert_equal "pi.lot@example.com", EntryWarnings.inbox("pi.lot@example.com")
      assert_nil EntryWarnings.inbox(nil)
    end

    test "an entry without an account carries no warnings" do
      entry = create(:raffle_entry)
      entry.update_columns(user_id: nil)

      warning = EntryWarnings.new(entry.raffle).for(entry.reload)

      assert_empty warning.shared_ip_with
      assert_not warning.new_account
    end
  end
end
