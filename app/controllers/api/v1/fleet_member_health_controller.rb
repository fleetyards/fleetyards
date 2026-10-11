# frozen_string_literal: true

module Api
  module V1
    # The roster's loose ends, for whoever can act on them: members who stopped
    # showing up, members not verified against the fleet's RSI org, and roles
    # nobody holds. A count and the first few of each; the members list, filtered the
    # same way, holds the rest.
    class FleetMemberHealthController < ::Api::BaseController
      DEFAULT_INACTIVE_DAYS = 30
      SAMPLE = 10

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[show]

      before_action :set_fleet

      def show
        authorize! with: FleetMembershipPolicy, to: :health?, context: {fleet: @fleet}

        members = @fleet.fleet_memberships.kept.accepted

        @inactive_days = inactive_days
        inactive = members.inactive_since(@inactive_days.days.ago)
        @inactive_count = inactive.count
        @inactive_members = inactive
          .joins(:user)
          .includes(*FleetMembership::ROSTER_PRELOADS)
          .order(Arel.sql("users.last_active_at ASC NULLS FIRST"), :id)
          .limit(SAMPLE)

        # Verification is against the fleet's RSI org, so without one there is
        # nothing to be unverified against.
        if @fleet.rsi_sid.present?
          unverified = members.where(verified: false)
          @unverified_count = unverified.count
          @unverified_members = unverified
            .includes(*FleetMembership::ROSTER_PRELOADS)
            .order(:accepted_at, :id)
            .limit(SAMPLE)
        end

        if current_fleet_membership&.has_access?(FleetMembership::CAPABILITY_PRIVILEGES[:read_roles])
          @empty_roles = @fleet.fleet_roles.ranked.where.not(id: members.where.not(fleet_role_id: nil).select(:fleet_role_id))
        end
      end

      private def inactive_days
        days = params[:inactive_days].presence&.to_i
        (days.nil? || days < 1) ? DEFAULT_INACTIVE_DAYS : days
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
