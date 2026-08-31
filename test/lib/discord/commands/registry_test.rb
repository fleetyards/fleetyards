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
    end
  end
end
