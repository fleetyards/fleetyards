# frozen_string_literal: true

module Discord
  module Commands
    # One table for both directions: `discord:commands:sync` publishes these
    # definitions to Discord, and the interactions endpoint dispatches incoming
    # commands through the same list. Splitting them is how a command ends up
    # registered but unhandled -- Discord shows it in the picker and the user
    # gets a timeout.
    module Registry
      # Discord application command option types.
      STRING = 3

      DEFINITIONS = [
        {
          name: "ship",
          description: "Look up a ship in the Fleetyards catalogue",
          handler: "Discord::Commands::Ship",
          options: [
            {
              name: "name",
              description: "Ship name, slug, or manufacturer",
              type: STRING,
              required: true
            }
          ]
        },
        {
          name: "loaner",
          description: "Show the loaners a ship comes with",
          handler: "Discord::Commands::Loaner",
          options: [
            {
              name: "name",
              description: "Ship name, slug, or manufacturer",
              type: STRING,
              required: true
            }
          ]
        },
        {
          name: "compare",
          description: "Compare two ships side by side",
          handler: "Discord::Commands::Compare",
          options: [
            {
              name: "first",
              description: "First ship",
              type: STRING,
              required: true
            },
            {
              name: "second",
              description: "Second ship",
              type: STRING,
              required: true
            }
          ]
        },
        {
          name: "hangar",
          description: "Show a member's public hangar",
          handler: "Discord::Commands::Hangar",
          options: [
            {
              name: "username",
              description: "Fleetyards username",
              type: STRING,
              required: true
            }
          ]
        },
        {
          name: "fleet",
          description: "Show this server's fleet on Fleetyards",
          handler: "Discord::Commands::Fleet",
          options: []
        }
      ].freeze

      def self.definition(name)
        DEFINITIONS.find { |definition| definition[:name] == name.to_s }
      end

      def self.handler_for(name)
        definition = definition(name)
        return nil if definition.blank?

        definition[:handler].constantize
      end

      # What Discord's PUT /applications/:id/commands accepts -- the handler is
      # ours and would be rejected as an unknown key.
      def self.payload
        DEFINITIONS.map do |definition|
          definition.except(:handler).deep_dup
        end
      end
    end
  end
end
