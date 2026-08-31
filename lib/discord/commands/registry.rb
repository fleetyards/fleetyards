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

      # Whether a command's answer is private to the caller.
      #
      # Declared here rather than decided by the command, because **Discord
      # fixes visibility at the deferred acknowledgement** -- before the job
      # that produces the answer has run. Flags on the follow-up payload are
      # ignored, so a command cannot make itself public afterwards, and one
      # command cannot post a public hit and a private miss.
      #
      # All five are lookups over data the site publishes, so they answer in
      # the channel: asking in company is the point. The cost is that their
      # refusals are public too.
      EPHEMERAL_BY_DEFAULT = false

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

      # Unknown commands answer privately: a "that command no longer exists"
      # belongs to whoever typed it.
      def self.ephemeral?(name)
        definition = definition(name)
        return true if definition.nil?

        definition.fetch(:ephemeral, EPHEMERAL_BY_DEFAULT)
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
          definition.except(:handler, :ephemeral).deep_dup
        end
      end
    end
  end
end
