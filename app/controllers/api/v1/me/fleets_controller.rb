# frozen_string_literal: true

module Api
  module V1
    module Me
      # One card per fleet the reader belongs to: who they are there, who is
      # around, what was last announced and what is waiting on them. Each count
      # is only answered to a member whose role could act on it, the same rule
      # the fleet's own dashboard follows.
      class FleetsController < ::Api::BaseController
        include FleetSubscriptionConcern
        include PresenceReadableConcern

        before_action :authenticate_user!, only: []
        before_action -> { doorkeeper_authorize! "user", "user:read" },
          unless: :user_signed_in?,
          only: %i[index]

        skip_verify_authorized only: %i[index]

        def index
          @memberships = current_resource_owner.fleet_memberships.kept.accepted
            .joins(:fleet).merge(Fleet.kept)
            .includes(:fleet_role, fleet: {logo_attachment: :blob})
            .order(primary: :desc, accepted_at: :asc)
            .to_a

          fleet_ids = @memberships.map(&:fleet_id)

          @member_counts = FleetMembership.kept.accepted.where(fleet_id: fleet_ids).group(:fleet_id).count
          @online_counts = online_counts(fleet_ids)
          @latest_announcements = latest_announcements(fleet_ids)
          @join_request_fleet_ids = answerable(:join_requests).map(&:fleet_id).to_set
          @transfer_fleet_ids = answerable(:transfers).map(&:fleet_id).to_set

          @requested_counts = FleetMembership.kept.requested
            .where(fleet_id: @join_request_fleet_ids.to_a).group(:fleet_id).count
          @transfer_counts = InventoryTransfer.pending
            .where(recipient_fleet_id: @transfer_fleet_ids.to_a).group(:recipient_fleet_id).count
        end

        # Somebody online who hides it counts nowhere, and the reader is not
        # someone they need told about.
        private def online_counts(fleet_ids)
          online = online_user_ids.to_a - [current_resource_owner.id]
          return {} if online.empty?

          FleetMembership.kept.accepted
            .joins(:user)
            .where(fleet_id: fleet_ids, user_id: online, users: {show_online_status: true})
            .group(:fleet_id).count
        end

        private def latest_announcements(fleet_ids)
          FleetAnnouncement.active
            .where(fleet_id: fleet_ids)
            .select("DISTINCT ON (fleet_id) fleet_announcements.*")
            .order(:fleet_id, created_at: :desc)
            .index_by(&:fleet_id)
        end

        private def answerable(kind)
          @memberships.select do |membership|
            capabilities = membership.capabilities

            case kind
            when :join_requests
              capabilities[:read_members] && capabilities[:update_members]
            when :transfers
              capabilities[:update_inventories] && logistics_available?(membership.fleet)
            end
          end
        end

        private def logistics_available?(fleet)
          return false unless feature_enabled?("fleet_logistics", fleet)

          !(Subscriptions::PREMIUM_FEATURES.include?(:logistics) && fleet_subscription_missing?(fleet))
        end
      end
    end
  end
end
