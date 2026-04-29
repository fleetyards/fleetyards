# frozen_string_literal: true

module Admin
  module Api
    module V1
      class FleetMembersController < ::Admin::Api::BaseController
        before_action :set_fleet
        before_action :set_member, only: %i[login_as]

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.base"))
        end

        def index
          member_query_params["sorts"] = sorting_params(FleetMembership, member_query_params[:sorts])

          @q = @fleet.fleet_memberships.ransack(member_query_params)

          @members = @q.result(distinct: true)
            .includes(:user, :fleet_role)
            .joins(:user)
            .page(params[:page])
            .per(per_page(FleetMembership))
        end

        def login_as
          sign_in(:user, @member.user)

          head :no_content
        end

        private def set_fleet
          @fleet = Fleet.find(params[:fleet_id])

          authorize! @fleet, with: ::Admin::FleetPolicy
        end

        private def set_member
          @member = @fleet.fleet_memberships
            .includes(:user)
            .find(params[:id])
        end

        private def member_query_params
          @member_query_params ||= params.permit(q: [
            :username_cont, :state_eq, :role_cont, :sorts, sorts: []
          ]).fetch(:q, {})
        end
      end
    end
  end
end
