# frozen_string_literal: true

module Api
  module V1
    class FleetMembersController < ::Api::BaseController
      include FleetMemberFiltersConcern

      after_action -> { pagination_header(:members) }, only: %i[index]

      def index
        authorize! :show, fleet

        scope = fleet.fleet_memberships

        member_query_params["sorts"] = sort_by_name(["created_at desc", "accepted_at desc"], "user_username asc")

        @q = scope.ransack(member_query_params)

        @members = @q.result(distinct: true)
          .includes(:user)
          .joins(:user)
          .page(params[:page])
          .per(per_page(FleetMembership))
      end

      private def fleet
        @fleet ||= current_user.fleets.where(slug: params[:slug]).first!
      end
    end
  end
end
