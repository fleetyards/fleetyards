# frozen_string_literal: true

require "test_helper"
require "discord/new_supporter"

module Discord
  class NewSupporterTest < ActiveSupport::TestCase
    test "builds content from the supporter's name and amount" do
      supporter = build(:supporter_contribution, :patreon, name: "Alice", amount_cents: 500, currency: "EUR")
      webhook = Discord::NewSupporter.new(supporter:)

      assert_equal I18n.t("discord.new_supporter.title"), webhook.title
      assert_equal I18n.t("discord.new_supporter.message", name: "Alice", amount: "5.00 EUR"), webhook.message
      assert_nil webhook.url
    end

    test "#run is a no-op when no admin endpoint is configured" do
      Rails.application.credentials.stubs(:discord_admin_endpoint).returns(nil)
      supporter = build(:supporter_contribution, :patreon)

      assert_nil Discord::NewSupporter.new(supporter:).run
    end
  end
end
