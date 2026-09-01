# frozen_string_literal: true

require "test_helper"
require "discord/commands/registry"

module Discord
  module Commands
    # Guards the failure mode the registry exists to prevent: a command that is
    # published to Discord but has no handler shows up in the picker and then
    # times out on the user.
    class RegistryTest < ActiveSupport::TestCase
      Registry = ::Discord::Commands::Registry

      # Every leaf a caller can actually invoke: a command without subcommands,
      # or each subcommand of one that has them.
      def self.invocable
        Registry::DEFINITIONS.flat_map do |definition|
          children = Registry.subcommands(definition)
          next [[definition[:name], nil]] if children.empty?

          children.map { |child| [definition[:name], child[:name]] }
        end
      end

      test "every published command has a handler that can run" do
        self.class.invocable.each do |name, subcommand|
          handler = Registry.handler_for(name, subcommand)
          label = [name, subcommand].compact.join(" ")

          assert handler.present?, "no handler for /#{label}"
          assert handler.new.respond_to?(:call), "#{handler} cannot be called"
        end
      end

      test "the payload sent to Discord carries no keys of ours" do
        Registry.payload.each do |command|
          assert_not_includes command.keys, :handler
        end
      end

      # A nested definition is published too, and Discord rejects the whole
      # payload over one unknown key -- leaving the previous command list live,
      # which reads as a sync that did nothing.
      test "the payload carries no keys of ours at any depth" do
        walk = lambda do |option|
          assert_not_includes option.keys, :handler
          assert_not_includes option.keys, :ephemeral

          Array(option[:options]).each { |child| walk.call(child) }
        end

        Registry.payload.each { |command| walk.call(command) }
      end

      test "every command declares a name and a description" do
        Registry.payload.each do |command|
          assert command[:name].present?
          assert command[:description].present?
        end
      end

      test "every subcommand declares a name and a description" do
        Registry.payload.each do |command|
          Array(command[:options])
            .select { |option| option[:type] == Registry::SUB_COMMAND }
            .each do |subcommand|
              assert subcommand[:name].present?
              assert subcommand[:description].present?, "/#{command[:name]} #{subcommand[:name]} has no description"
            end
        end
      end

      test "an unregistered name resolves to no handler" do
        assert_nil Registry.handler_for("definitely-not-a-command")
      end

      test "a subcommand resolves to its own handler" do
        assert_equal ::Discord::Commands::Fleet, Registry.handler_for("fleet", "info")
      end

      # Discord refuses to invoke a command that has subcommands, so resolving a
      # bare call to the parent would be inventing a command that cannot exist.
      test "a command with subcommands cannot be invoked bare" do
        assert_nil Registry.handler_for("fleet")
        assert Registry.ephemeral?("fleet"), "a bare /fleet would answer in the channel"
      end

      test "an unknown subcommand resolves to no handler" do
        assert_nil Registry.handler_for("fleet", "definitely-not-a-subcommand")
        assert Registry.ephemeral?("fleet", "definitely-not-a-subcommand")
      end

      test "a subcommand named on a command that has none resolves to no handler" do
        assert_nil Registry.handler_for("ship", "info")
      end

      # Discord fixes visibility at the deferred acknowledgement and ignores
      # flags on the follow-up, so this cannot live in the command: the answer
      # is needed before the command has run.
      #
      # Named one by one rather than derived from the list: these five answer in
      # company on purpose, and a later command turning private must not be able
      # to make this assertion pass by widening it.
      test "the catalogue lookups and the fleet overview answer in the channel" do
        [["ship", nil], ["loaner", nil], ["compare", nil], ["hangar", nil], ["fleet", "info"]].each do |name, subcommand|
          refute Registry.ephemeral?(name, subcommand),
            "/#{[name, subcommand].compact.join(" ")} would answer privately"
        end
      end

      # The point of these two commands. A public answer would post someone's
      # private hangar into the channel they typed it in.
      test "a command about your own data answers privately" do
        ["myhangar", "mywishlist"].each do |name|
          assert Registry.ephemeral?(name),
            "/#{name} would answer in the channel"
        end
      end

      # The token is the credential: a public answer hands the fleet to everyone
      # in the channel, guests included.
      test "an invite link answers privately" do
        assert Registry.ephemeral?("fleet", "invite"), "/fleet invite would answer in the channel"
      end

      # A roster is usernames and RSI handles, and the guild it was typed in may
      # have guests.
      test "the member list answers privately" do
        assert Registry.ephemeral?("fleet", "members"), "/fleet members would answer in the channel"
      end

      # A "that command no longer exists" belongs to whoever typed it.
      test "an unregistered name answers privately" do
        assert Registry.ephemeral?("definitely-not-a-command")
      end

      test "the visibility flag is ours and never reaches Discord" do
        Registry.payload.each do |command|
          assert_not_includes command.keys, :ephemeral
        end
      end
    end
  end
end
