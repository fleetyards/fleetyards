# frozen_string_literal: true

module Api
  module V1
    class FleetMembersController < ::Api::BaseController
      after_action -> { pagination_header(:members) }, only: %i[index]

      def index
        authorize! :show, fleet

        scope = fleet.fleet_memberships

        member_query_params['sorts'] = sort_by_name(['created_at desc', 'accepted_at desc'], 'user_username asc')

        @q = scope.ransack(member_query_params)

        @members = @q.result(distinct: true)
          .includes(:user)
          .joins(:user)
          .page(params[:page])
          .per(per_page(FleetMembership))
      end

      def quick_stats
        authorize! :show, fleet
        @q = fleet.fleet_memberships.ransack(member_query_params)

        members = @q.result

        @quick_stats = OpenStruct.new(
          total: members.size,
          metrics: {
            total_admins: members.where(role: :admin).size,
            total_officers: members.where(role: :officer).size,
            total_members: members.where(role: :member).size
          }
        )
      end

      private def fleet
        @fleet ||= current_user.fleets.where(slug: params[:slug]).first!
      end

      private def member_query_params
        @member_query_params ||= query_params(
          :username_cont, sorts: [], role_in: []
        )
      end
    end
  end
end
