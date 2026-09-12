# frozen_string_literal: true

module Inventories
  # Who finds out about a transfer, and what they are told.
  #
  # One notification per event, not one per line. A ten-line shipment accepted
  # into a fleet inventory announces itself once -- `FleetInventoryItem` stays
  # quiet for entries a transfer wrote, which is what keeps the other ten from
  # arriving beside this one.
  class TransferNotifier
    def initialize(transfer)
      @transfer = transfer
    end

    # Only a transfer somebody has to answer is worth announcing. An immediate
    # one was carried out by the person reading the notification.
    def notify_sent
      return if @transfer.immediate?

      recipients.each do |user|
        ::Notification.notify!(
          user:,
          type: :inventory_transfer_received,
          title: received_title,
          link: inbox_link,
          record: @transfer
        )
      end
    end

    def notify_resolved
      return if @transfer.immediate?

      initiator = @transfer.initiated_by
      return if initiator.blank?
      # The person who answered it already knows.
      return if initiator == @transfer.resolved_by

      ::Notification.notify!(
        user: initiator,
        type: :inventory_transfer_resolved,
        title: I18n.t(
          "notifications.inventory_transfer_resolved.title",
          recipient: party_name(@transfer.recipient_party),
          outcome: @transfer.aasm_state
        ),
        link: inbox_link,
        record: @transfer
      )
    end

    # A user is one person. A fleet is whoever could actually answer for it --
    # the same membership walk `FleetInventoryItem` already does for its own
    # notification, asked with the privileges that let somebody accept.
    private def recipients
      case @transfer.recipient_party
      when ::User then [@transfer.recipient]
      when ::Fleet then fleet_recipients(@transfer.recipient_fleet)
      else []
      end
    end

    private def fleet_recipients(fleet)
      fleet.fleet_memberships.kept.accepted.includes(:fleet_role, :user)
        .select { |membership| membership.has_access?(TransferAuthorizer::WRITE_PRIVILEGES) }
        .filter_map(&:user)
        .uniq
    end

    private def received_title
      count = @transfer.dispatched_entries.count
      sender = party_name(@transfer.sender_party)

      if @transfer.recipient_fleet.present?
        I18n.t("notifications.inventory_transfer_received.title_fleet",
          sender:, count:, fleet: @transfer.recipient_fleet.name)
      else
        I18n.t("notifications.inventory_transfer_received.title", sender:, count:)
      end
    end

    private def inbox_link
      if @transfer.recipient_fleet.present?
        "/fleets/#{@transfer.recipient_fleet.slug}/logistics/transfers"
      else
        "/hangar/transfers"
      end
    end

    private def party_name(party)
      case party
      when ::User then party.username
      when ::Fleet then party.name
      end
    end
  end
end
