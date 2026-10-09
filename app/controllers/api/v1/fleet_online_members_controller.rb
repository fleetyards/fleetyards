# frozen_string_literal: true

module Api
  module V1
    # Who in the fleet is around right now, for the dashboard. Read off the
    # presence set like every other online dot, and as private as they are: a
    # member who hides their status is left out rather than shown as offline.
    class FleetOnlineMembersController < ::Api::BaseController
      LIMIT = 24

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index]

      before_action :set_fleet

      def index
        authorize! with: FleetMembershipPolicy, context: {fleet: @fleet}

        online = @fleet.fleet_memberships.kept.accepted
          .joins(:user)
          .where(user_id: online_user_ids.to_a, users: {show_online_status: true})
          .where.not(user_id: current_resource_owner.id)
          .includes(user: {avatar_attachment: :blob})
          .to_a

        # The reader's friends first: the people they would go and find.
        @friend_ids = current_resource_owner.friends.where(id: online.map(&:user_id)).pluck(:id).to_set
        @total_count = online.size
        @members = online
          .sort_by { |membership| [@friend_ids.include?(membership.user_id) ? 0 : 1, membership.user.username.downcase] }
          .first(LIMIT)
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])
        authorize! @fleet, to: :show?
      end
    end
  end
end
