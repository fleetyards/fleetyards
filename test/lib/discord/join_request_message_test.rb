# frozen_string_literal: true

require "test_helper"

module Discord
  class JoinRequestMessageTest < ActiveSupport::TestCase
    setup do
      @fleet = create(:fleet, name: "Test Wing")
      @applicant = create(:user, username: "New_comer")
      @membership = @fleet.fleet_memberships.create!(user: @applicant, fleet_role: @fleet.fleet_roles.find_by(name: "Member"))
      @membership.update!(aasm_state: "requested", requested_at: Time.zone.now)
    end

    def buttons(payload)
      payload[:components].first[:components]
    end

    test "a custom_id names the decision and the request" do
      custom_id = JoinRequestMessage.custom_id("accept", @membership.id)

      assert_equal({decision: "accept", membership_id: @membership.id}, JoinRequestMessage.parse(custom_id))
    end

    test "a custom_id that is not ours is not parsed" do
      assert_nil JoinRequestMessage.parse(nil)
      assert_nil JoinRequestMessage.parse("fleet_request:promote:#{@membership.id}")
      assert_nil JoinRequestMessage.parse("other:accept:#{@membership.id}")
      assert_nil JoinRequestMessage.parse("fleet_request:accept:")
    end

    test "a pending request offers both answers" do
      payload = JoinRequestMessage.new(@membership).pending_payload

      assert_includes payload[:content], "New\\_comer"
      assert_includes payload[:content], "Test Wing"
      assert_equal %w[accept decline], buttons(payload).map { |button| JoinRequestMessage.parse(button[:custom_id])[:decision] }
      assert buttons(payload).none? { |button| button[:disabled] }
    end

    test "a settled request names the outcome and who answered, and disables the buttons" do
      officer = create(:user, username: "Officer")
      @membership.update!(aasm_state: "accepted")

      payload = JoinRequestMessage.new(@membership).settled_payload(officer: officer)

      assert_includes payload[:content], I18n.t("discord.join_request.accepted_by", officer: "Officer")
      assert buttons(payload).all? { |button| button[:disabled] }
    end

    test "a request settled elsewhere reads without a name" do
      @membership.update!(aasm_state: "declined")

      assert_includes JoinRequestMessage.new(@membership).settled_payload[:content], I18n.t("discord.join_request.declined")
    end

    test "a request neither accepted nor declined reads as no longer pending" do
      @membership.update!(aasm_state: "created")

      assert_includes JoinRequestMessage.new(@membership).settled_payload[:content], I18n.t("discord.join_request.closed")
    end

    test "the shared message stays in the default locale whoever clicks it" do
      content = I18n.with_locale(:de) { JoinRequestMessage.new(@membership).pending_payload[:content] }

      assert_equal I18n.t("discord.join_request.summary",
        username: "New\\_comer",
        fleet: "Test Wing",
        url: "https://#{Rails.configuration.app.domain}/fleets/#{@fleet.slug}/members/"), content
    end
  end
end
