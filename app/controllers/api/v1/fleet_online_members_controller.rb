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

        members = @fleet.fleet_memberships.kept.accepted
        online_ids = online_member_ids(members)
        online_ids.delete(current_resource_owner.id)

        online = members
          .joins(:user)
          .where(user_id: online_ids.to_a, users: {show_online_status: true})
          .includes(user: {avatar_attachment: :blob})
          .to_a

        # The reader's friends first: the people they would go and find.
        @friend_ids = current_resource_owner.friends.where(id: online.map(&:user_id)).pluck(:id).to_set
        @total_count = online.size
        @members = online
          .sort_by { |membership| [@friend_ids.include?(membership.user_id) ? 0 : 1, shown_name(membership).downcase] }
          .first(LIMIT)
      end

      # The intersection is taken from whichever side is smaller: a large fleet
      # is cheaper to filter by who is online, a small one by its own roster.
      # The panel polls every minute for every open dashboard, so neither the
      # whole site's presence nor a whole roster should move on each request.
      private def online_member_ids(members)
        online = online_user_ids
        return members.where(user_id: online.to_a).pluck(:user_id).to_set if online.size < members.count

        members.pluck(:user_id).to_set & online
      end

      # Sorted by the name the panel shows, or the order reads as random.
      private def shown_name(membership)
        membership.nickname.presence || membership.user.username
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])
        authorize! @fleet, to: :show?
      end
    end
  end
end
