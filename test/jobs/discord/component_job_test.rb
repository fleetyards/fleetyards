# frozen_string_literal: true

require "test_helper"

module Discord
  class ComponentJobTest < ActiveSupport::TestCase
    setup do
      @client = mock("Discord::InteractionClient")
      ::Discord::InteractionClient.stubs(:new).returns(@client)
    end

    def context(overrides = {})
      {
        "application_id" => "488788875699945472",
        "token" => "interaction-token",
        "custom_id" => "fleet_request:accept:#{SecureRandom.uuid}",
        "guild_id" => "guild-1",
        "discord_user_id" => "officer-uid",
        "locale" => "en",
        "requested_at" => Time.current.to_i
      }.merge(overrides)
    end

    test "an update edits the message the button is on" do
      update = {content: "settled", components: []}
      Components::FleetRequest.any_instance.stubs(:call).returns({update: update})
      @client.expects(:edit_original).with(update)
      @client.expects(:create_followup).never

      ComponentJob.new.perform(context)
    end

    test "a reply is sent privately and the message is left alone" do
      Components::FleetRequest.any_instance.stubs(:call).returns({reply: {content: "no"}})
      @client.expects(:edit_original).never
      @client.expects(:create_followup).with({content: "no"})

      ComponentJob.new.perform(context)
    end

    test "the private reply is in the clicker's locale" do
      @client.expects(:create_followup).with { |payload| payload[:content] == I18n.t("discord.commands.fleet.not_bound", locale: :de) }

      ComponentJob.new.perform(context("locale" => "de"))
    end

    test "a custom_id that is not ours is answered with a failure" do
      @client.expects(:create_followup).with({content: I18n.t("discord.commands.failed")})

      ComponentJob.new.perform(context("custom_id" => "something:else"))
    end

    test "a handler that raises still answers with a failure" do
      Components::FleetRequest.any_instance.stubs(:call).raises(StandardError, "boom")
      @client.expects(:edit_original).never
      @client.expects(:create_followup).with({content: I18n.t("discord.commands.failed")})

      ComponentJob.new.perform(context)
    end

    test "a click whose token has expired is dropped" do
      @client.expects(:edit_original).never
      @client.expects(:create_followup).never

      ComponentJob.new.perform(context("requested_at" => 20.minutes.ago.to_i))
    end
  end
end
