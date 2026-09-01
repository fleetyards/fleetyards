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
      SUB_COMMAND = 1
      STRING = 3
      INTEGER = 4
      BOOLEAN = 5
      USER = 6

      # Whether a command's answer is private to the caller.
      #
      # Declared here rather than decided by the command, because **Discord
      # fixes visibility at the deferred acknowledgement** -- before the job
      # that produces the answer has run. Flags on the follow-up payload are
      # ignored, so a command cannot make itself public afterwards, and one
      # command cannot post a public hit and a private miss.
      #
      # The catalogue lookups answer in the channel: asking in company is the
      # point, and the cost is that their refusals are public too. A command
      # about one person's own data, or about one fleet's, sets
      # `ephemeral: true` instead.
      EPHEMERAL_BY_DEFAULT = false

      # A subcommand is an option of type SUB_COMMAND that carries a `handler`
      # of its own. It lives in the same list Discord is sent rather than in a
      # parallel one, so there is no second place a subcommand can be declared
      # and forgotten.
      #
      # **A command with subcommands cannot be invoked bare.** Discord rejects a
      # call to the parent, which is why the fleet overview moved from `/fleet`
      # to `/fleet info` when the first subcommand arrived. Subcommand *groups*
      # (type 2, a level deeper) are not supported: nothing needs them, and the
      # controller reads exactly one level.
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
          description: "This server's fleet on Fleetyards",
          options: [
            {
              name: "info",
              description: "Show this server's fleet on Fleetyards",
              type: SUB_COMMAND,
              handler: "Discord::Commands::Fleet",
              options: []
            },
            {
              name: "invite",
              description: "Create an invite link for this server's fleet",
              type: SUB_COMMAND,
              handler: "Discord::Commands::FleetInvite",
              ephemeral: true,
              options: [
                {
                  name: "limit",
                  description: "How many people may use the link",
                  type: INTEGER,
                  required: false,
                  min_value: 1
                },
                {
                  name: "expires_in",
                  description: "How long the link stays valid",
                  type: STRING,
                  required: false,
                  choices: [
                    {name: "1 hour", value: "1h"},
                    {name: "24 hours", value: "24h"},
                    {name: "7 days", value: "7d"},
                    {name: "Never", value: "never"}
                  ]
                }
              ]
            },
            {
              name: "members",
              description: "List this server's fleet members, only to you",
              type: SUB_COMMAND,
              handler: "Discord::Commands::FleetMembers",
              ephemeral: true,
              options: [
                {
                  name: "filter",
                  description: "Which members to list",
                  type: STRING,
                  required: false,
                  choices: [
                    {name: "Members", value: "all"},
                    {name: "Pending requests", value: "pending"}
                  ]
                }
              ]
            }
          ]
        },
        {
          name: "myhangar",
          description: "Show your own hangar, only to you",
          handler: "Discord::Commands::MyHangar",
          ephemeral: true,
          options: []
        },
        {
          name: "mywishlist",
          description: "Show your own wishlist, only to you",
          handler: "Discord::Commands::MyWishlist",
          ephemeral: true,
          options: []
        }
      ].freeze

      def self.definition(name)
        DEFINITIONS.find { |definition| definition[:name] == name.to_s }
      end

      def self.subcommands(definition)
        Array(definition&.dig(:options)).select { |option| option[:type] == SUB_COMMAND }
      end

      # The definition a call resolves to. Nothing resolves to a parent that has
      # subcommands: Discord cannot invoke it, so treating a bare call as one is
      # inventing a command that does not exist.
      def self.resolve(name, subcommand = nil)
        definition = definition(name)
        return nil if definition.blank?

        children = subcommands(definition)
        return children.find { |child| child[:name] == subcommand.to_s } if children.any?

        subcommand.blank? ? definition : nil
      end

      # Unknown commands answer privately: a "that command no longer exists"
      # belongs to whoever typed it.
      def self.ephemeral?(name, subcommand = nil)
        definition = resolve(name, subcommand)
        return true if definition.nil?

        definition.fetch(:ephemeral, EPHEMERAL_BY_DEFAULT)
      end

      def self.handler_for(name, subcommand = nil)
        definition = resolve(name, subcommand)
        return nil if definition.blank?

        definition[:handler]&.constantize
      end

      # What Discord's PUT /applications/:id/commands accepts. `handler` and
      # `ephemeral` are ours and are rejected as unknown keys **at any depth** --
      # and because the endpoint is a full replacement, a rejected payload leaves
      # the previous command list live, which reads as a sync that did nothing.
      def self.payload
        DEFINITIONS.map { |definition| publishable(definition) }
      end

      private_class_method def self.publishable(definition)
        cleaned = definition.except(:handler, :ephemeral).deep_dup
        return cleaned if cleaned[:options].blank?

        cleaned.merge(options: cleaned[:options].map { |option| publishable(option) })
      end
    end
  end
end
