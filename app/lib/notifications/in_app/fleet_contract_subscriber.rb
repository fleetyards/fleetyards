# frozen_string_literal: true

module Notifications
  module InApp
    # Who hears about a contract.
    #
    # Two audiences, and they are deliberately different. A *published* contract
    # goes to everyone who can see the board, because it is an offer of work.
    # Everything after that goes to the small set of people it actually concerns
    # -- the lead, the person who asked to join, the managers who have to pay --
    # so a fleet of three hundred does not get three hundred notifications every
    # time somebody moves some cargo.
    class FleetContractSubscriber
      EVENT_NAMES = %w[
        fleet_contract.published
        fleet_contract.claimed
        fleet_contract.fulfilled
        fleet_contract_assignment.requested
        fleet_contract_assignment.answered
      ].freeze

      MANAGE_PRIVILEGES = ["fleet:manage", "fleet:contracts:manage"].freeze
      READ_PRIVILEGES = ["fleet:manage", "fleet:contracts:manage", "fleet:contracts:read"].freeze

      def self.register!
        EVENT_NAMES.each do |name|
          ActiveSupport::Notifications.subscribe(name) do |*args|
            payload = ActiveSupport::Notifications::Event.new(*args).payload
            new(name, payload).call
          rescue => e
            Rails.logger.error("[FleetContractSubscriber] #{name} failed: #{e.class}: #{e.message}")
          end
        end
      end

      def initialize(event_name, payload)
        @event_name = event_name
        @payload = payload
      end

      def call
        case @event_name
        when "fleet_contract.published" then handle_published
        when "fleet_contract.claimed" then handle_claimed
        when "fleet_contract.fulfilled" then handle_fulfilled
        when "fleet_contract_assignment.requested" then handle_crew_requested
        when "fleet_contract_assignment.answered" then handle_crew_answered
        end
      end

      private

      def contract
        @payload[:contract] || @payload[:assignment]&.fleet_contract
      end

      def assignment
        @payload[:assignment]
      end

      def handle_published
        return if contract.blank?

        readers.each do |user|
          notify(user, :fleet_contract_published,
            title: I18n.t("notifications.fleet_contract.published.title",
              fleet: contract.fleet.name, title: contract.title),
            body: I18n.t("notifications.fleet_contract.published.body",
              fleet: contract.fleet.name))
        end
      end

      def handle_claimed
        return if contract.blank?

        claimant = @payload[:user] || contract.lead

        managers.each do |user|
          next if user == claimant

          notify(user, :fleet_contract_claimed,
            title: I18n.t("notifications.fleet_contract.claimed.title",
              user: claimant&.username || "A member", title: contract.title))
        end
      end

      def handle_fulfilled
        return if contract.blank?

        # The crew are told as well as the managers: a fulfilled contract is
        # what they are waiting on before they can be paid.
        (managers + contract.contractor_assignments.includes(:user).map(&:user)).compact.uniq.each do |user|
          notify(user, :fleet_contract_fulfilled,
            title: I18n.t("notifications.fleet_contract.fulfilled.title", title: contract.title))
        end
      end

      def handle_crew_requested
        return if assignment.blank? || contract.blank?

        # The lead answers for their own contract, so they are the audience --
        # falling back to the managers only when there is no lead to ask.
        recipients = [contract.lead].compact
        recipients = managers if recipients.empty?

        recipients.each do |user|
          notify(user, :fleet_contract_crew_requested,
            title: I18n.t("notifications.fleet_contract.crew_requested.title",
              user: assignment.user&.username || "A member", title: contract.title))
        end
      end

      def handle_crew_answered
        return if assignment.blank? || contract.blank?
        return if assignment.user.blank?

        key = assignment.accepted? ? "accepted" : "declined"

        notify(assignment.user, :fleet_contract_crew_answered,
          title: I18n.t("notifications.fleet_contract.crew_#{key}.title", title: contract.title))
      end

      def memberships
        contract.fleet.fleet_memberships.where(aasm_state: "accepted").includes(:user, :fleet_role)
      end

      def readers
        memberships.select { |membership| membership.has_access?(READ_PRIVILEGES) }.filter_map(&:user)
      end

      def managers
        memberships.select { |membership| membership.has_access?(MANAGE_PRIVILEGES) }.filter_map(&:user)
      end

      def notify(user, type, title:, body: nil)
        return if user.blank?

        Notification.notify!(
          user: user,
          type: type,
          title: title,
          body: body,
          link: "/fleets/#{contract.fleet.slug}/contracts/#{contract.slug}",
          icon: "clipboard-list",
          record: contract
        )
      end
    end
  end
end
