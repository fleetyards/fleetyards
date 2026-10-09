# frozen_string_literal: true

module Api
  module V1
    # The roster's loose ends, for whoever can act on them: members who stopped
    # showing up, members the fleet's RSI org does not know, and roles nobody
    # holds. Counts and a few names each; the members page is where they are
    # worked through.
    class FleetHealthController < ::Api::BaseController
      INACTIVE_AFTER = 30.days
      SAMPLE = 5

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[show]

      before_action :set_fleet

      def show
        authorize! with: FleetMembershipPolicy, to: :accept_request?, context: {fleet: @fleet}

        members = @fleet.fleet_memberships.kept.accepted

        inactive = members.joins(:user)
          .where("users.last_active_at IS NULL OR users.last_active_at < ?", INACTIVE_AFTER.ago)
        @inactive_count = inactive.count
        @inactive_sample = inactive.includes(user: {avatar_attachment: :blob})
          .order(Arel.sql("users.last_active_at ASC NULLS FIRST"))
          .limit(SAMPLE)

        # Verification is against the fleet's RSI org, so without one there is
        # nothing to be unverified against.
        if @fleet.rsi_sid.present?
          unverified = members.where(verified: false)
          @unverified_count = unverified.count
          @unverified_sample = unverified.includes(user: {avatar_attachment: :blob}).order(:accepted_at).limit(SAMPLE)
        end

        if current_fleet_membership&.capabilities&.dig(:read_roles)
          @empty_roles = @fleet.fleet_roles.ranked.where.not(id: members.select(:fleet_role_id))
        end
      end

      private def current_fleet_membership
        current_resource_owner.fleet_memberships.kept.accepted.find_by(fleet: @fleet)
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])
        authorize! @fleet, to: :show?
      end
    end
  end
end
