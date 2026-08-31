# frozen_string_literal: true

require "test_helper"
require "discord/commands/registry"

module Discord
  module Commands
    # Guards the failure mode the registry exists to prevent: a command that is
    # published to Discord but has no handler shows up in the picker and then
    # times out on the user.
    class RegistryTest < ActiveSupport::TestCase
      test "every published command has a handler that can run" do
        ::Discord::Commands::Registry::DEFINITIONS.each do |definition|
          handler = ::Discord::Commands::Registry.handler_for(definition[:name])

          assert handler.present?, "no handler for /#{definition[:name]}"
          assert handler.new.respond_to?(:call), "#{handler} cannot be called"
        end
      end

      test "the payload sent to Discord carries no keys of ours" do
        ::Discord::Commands::Registry.payload.each do |command|
          assert_not_includes command.keys, :handler
        end
      end

      test "every command declares a name and a description" do
        ::Discord::Commands::Registry.payload.each do |command|
          assert command[:name].present?
          assert command[:description].present?
        end
      end

      test "an unregistered name resolves to no handler" do
        assert_nil ::Discord::Commands::Registry.handler_for("definitely-not-a-command")
      end

      # Discord fixes visibility at the deferred acknowledgement and ignores
      # flags on the follow-up, so this cannot live in the command: the answer
      # is needed before the command has run.
      test "every command answers in the channel" do
        ::Discord::Commands::Registry::DEFINITIONS.each do |definition|
          refute ::Discord::Commands::Registry.ephemeral?(definition[:name]),
            "/#{definition[:name]} would answer privately"
        end
      end

      # A "that command no longer exists" belongs to whoever typed it.
      test "an unregistered name answers privately" do
        assert ::Discord::Commands::Registry.ephemeral?("definitely-not-a-command")
      end

      test "the visibility flag is ours and never reaches Discord" do
        ::Discord::Commands::Registry.payload.each do |command|
          assert_not_includes command.keys, :ephemeral
        end
      end
    end
  end
end
