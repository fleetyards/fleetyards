# frozen_string_literal: true

require "test_helper"

module Discord
  class CommandJobTest < ActiveSupport::TestCase
    setup do
      @client = mock("Discord::InteractionClient")
      ::Discord::InteractionClient.stubs(:new).returns(@client)
      # The lookup matches on the model slug and the manufacturer slug too, and
      # both are built from the manufacturer -- a random one can contain the
      # "not found" query as a substring and answer with this ship.
      create(:model,
        name: "Carrack",
        classification: "explorer",
        manufacturer: create(:manufacturer, name: "Anvil Aerospace", code: "ANVL"))
    end

    def context(overrides = {})
      {
        "application_id" => "488788875699945472",
        "token" => "interaction-token",
        "command" => "ship",
        "options" => {"name" => "Carrack"},
        "locale" => "en",
        "requested_at" => Time.current.to_i
      }.merge(overrides)
    end

    test "delivers the command's payload as the interaction's answer" do
      @client.expects(:edit_original).with { |payload| payload[:embeds].first[:title] == "Carrack" }

      ::Discord::CommandJob.new.perform(context)
    end

    test "answers in the locale the interaction carried" do
      @client.expects(:edit_original).with do |payload|
        payload[:content].to_s.include?("Kein Schiff")
      end

      ::Discord::CommandJob.new.perform(context("locale" => "de", "options" => {"name" => "Nope"}))
    end

    test "a Discord locale with a region falls back to the language" do
      @client.expects(:edit_original).with do |payload|
        payload[:content].to_s.include?("Kein Schiff")
      end

      ::Discord::CommandJob.new.perform(context("locale" => "de-DE", "options" => {"name" => "Nope"}))
    end

    # The interaction is already showing "thinking..." -- an unanswered one
    # stays there, so a failure still has to say something.
    test "a command that raises still answers with a failure message" do
      ::Discord::Commands::Ship.any_instance.stubs(:call).raises(StandardError, "boom")
      @client.expects(:edit_original).with { |payload| payload[:content] == I18n.t("discord.commands.failed") }

      ::Discord::CommandJob.new.perform(context)
    end

    test "a command that raises is not retried" do
      ::Discord::Commands::Ship.any_instance.stubs(:call).raises(StandardError, "boom")
      @client.stubs(:edit_original)

      assert_nothing_raised { ::Discord::CommandJob.new.perform(context) }
    end

    test "a transport failure is left to Sidekiq to retry" do
      @client.stubs(:edit_original).raises(::Discord::InteractionClient::Error, "503")

      assert_raises(::Discord::InteractionClient::Error) do
        ::Discord::CommandJob.new.perform(context)
      end
    end

    test "an unknown command answers instead of timing out" do
      @client.expects(:edit_original).with { |payload| payload[:content] == I18n.t("discord.commands.failed") }

      ::Discord::CommandJob.new.perform(context("command" => "nope"))
    end

    # Nothing can be delivered once the token has expired, and retrying only
    # burns rate limit.
    test "does not answer an interaction whose token has expired" do
      @client.expects(:edit_original).never
      expired = (Time.current - ::Discord::InteractionClient::TOKEN_TTL - 1.minute).to_i

      ::Discord::CommandJob.new.perform(context("requested_at" => expired))
    end

    test "answers when the token is still within its window" do
      @client.expects(:edit_original).once
      recent = (Time.current - 1.minute).to_i

      ::Discord::CommandJob.new.perform(context("requested_at" => recent))
    end
  end
end
