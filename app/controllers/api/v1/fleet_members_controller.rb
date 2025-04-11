# frozen_string_literal: true

module Api
  module V1
    class FleetMembersController < ::Api::BaseController
      include FleetMemberFiltersConcern

      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t("messages.record_not_found.fleet", slug: params[:slug]))
      end

      after_action -> { pagination_header(:members) }, only: %i[index]

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?

      def index
        authorize! :show, fleet

        scope = fleet.fleet_memberships

        member_query_params["sorts"] = sorting_params(FleetMembership)

        @q = scope.ransack(member_query_params)

        @members = @q.result(distinct: true)
          .includes(:user)
          .joins(:user)
          .page(params[:page])
          .per(per_page(FleetMembership))
      end

      def create
        user = User.find_by(normalized_username: params[:username]&.downcase)

        @member = fleet.fleet_memberships.new(
          user: user,
          role: :member,
          fleet_role: fleet.entry_role,
          invited_by: current_user.id
        )

        authorize! :create, member

        if member.save
          member.invite!
          render :create, status: :created
        else
          render json: ValidationError.new("fleet_members.create", errors: member.errors), status: :bad_request
        end
      end

      def accept
        authorize! :accept_request, member

        unless member.accept_request!
          render json: ValidationError.new("fleet_members.accept", errors: member.errors), status: :bad_request
        end
      end

      def decline
        authorize! :decline_request, member

        unless member.decline!
          render json: ValidationError.new("fleet_members.decline", errors: member.errors), status: :bad_request
        end
      end

      def promote
        authorize! :promote, member

        member.promote
      end

      def demote
        authorize! :demote, member

        member.demote
      end

      def destroy
        authorize! :destroy, member

        return if member.destroy

        render json: ValidationError.new("fleet_members.destroy", errors: member.errors), status: :bad_request
      end

      private def fleet
        @fleet ||= current_user.fleets.where(slug: params[:fleet_slug]).first!
      end

      private def member
        @member ||= fleet.fleet_memberships
          .includes(:user)
          .joins(:user)
          .find_by!(users: {normalized_username: params[:username].downcase})
      end
    end
  end
end
