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

    test "an address of our own load balancer is no shared IP" do
      Rails.application.config.action_dispatch.stubs(:trusted_proxies).returns([IPAddr.new("91.98.1.57")])
      raffle = create(:raffle)
      entries = [create(:raffle_entry, raffle:), create(:raffle_entry, raffle:)]
      entries.each { |entry| entry.user.update_columns(current_sign_in_ip: "91.98.1.57", last_sign_in_ip: "10.0.0.4") }

      warnings = EntryWarnings.new(raffle)

      entries.each { |entry| assert_empty warnings.for(entry.reload).shared_ip_with }
    end

    test "a visitor address shared by two entrants is" do
      raffle = create(:raffle)
      first, second = create(:raffle_entry, raffle:), create(:raffle_entry, raffle:)
      [first, second].each { |entry| entry.user.update_columns(current_sign_in_ip: "203.0.113.7") }

      assert_equal [second.user.username], EntryWarnings.new(raffle).for(first.reload).shared_ip_with
    end
  end
end
