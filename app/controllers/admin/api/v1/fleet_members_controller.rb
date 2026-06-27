# frozen_string_literal: true

module Admin
  module Api
    module V1
      class FleetMembersController < ::Admin::Api::BaseController
        before_action :set_fleet
        before_action :set_member, only: %i[show update destroy login_as]

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.base"))
        end

        def index
          member_query_params["sorts"] = sorting_params(FleetMembership, member_query_params[:sorts])

          @q = @fleet.fleet_memberships.kept.ransack(member_query_params)

          @members = @q.result(distinct: true)
            .includes(:user, :fleet_role)
            .joins(:user)
            .page(params[:page])
            .per(per_page(FleetMembership))
        end

        def show
        end

        def update
          target_role = @fleet.fleet_roles.find_by(id: params[:fleet_role_id])

          if target_role.nil?
            return render json: ValidationError.new(
              "fleet_members.update",
              message: I18n.t("messages.admin.fleet_members.invalid_role")
            ), status: :bad_request
          end

          if demoting_last_admin?(target_role)
            return render json: ValidationError.new(
              "fleet_members.update",
              message: I18n.t("messages.admin.fleet_members.cannot_demote_last_admin")
            ), status: :bad_request
          end

          return render :show if @member.update(fleet_role: target_role)

          render json: ValidationError.new("fleet_members.update", errors: @member.errors), status: :bad_request
        end

        def destroy
          return head :no_content if @member.discard

          render json: ValidationError.new("fleet_members.destroy", errors: @member.errors), status: :bad_request
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
          @member = @fleet.fleet_memberships.kept
            .includes(:user, :fleet_role)
            .find(params[:id])
        end

        private def demoting_last_admin?(target_role)
          current_role = @member.fleet_role
          return false unless current_role&.permanent?
          return false if target_role.permanent?

          current_role.fleet_memberships.kept.count == 1
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
