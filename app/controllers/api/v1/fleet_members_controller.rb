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
        unless: :user_signed_in?,
        only: %i[index]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[create accept_request decline_request promote demote destroy]

      before_action :set_fleet, only: %i[index create accept_request decline_request promote demote destroy]
      before_action :set_member, only: %i[accept_request decline_request promote demote destroy]

      def index
        authorize! with: FleetMembershipPolicy, context: {fleet: @fleet}

        scope = @fleet.fleet_memberships

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

        @member = @fleet.fleet_memberships.new(
          user: user,
          fleet_role: @fleet.fleet_roles.ranked.last,
          invited_by: current_user.id
        )

        authorize! @member

        if @member.save
          @member.invite!
          render :create, status: :created
        else
          render json: ValidationError.new("fleet_members.create", errors: @member.errors), status: :bad_request
        end
      end

      def accept_request
        unless @member.accept_request!
          render json: ValidationError.new("fleet_members.accept", errors: @member.errors), status: :bad_request
        end
      end

      def decline_request
        unless @member.decline!
          render json: ValidationError.new("fleet_members.decline", errors: @member.errors), status: :bad_request
        end
      end

      def promote
        @member.promote
      end

      def demote
        return if @member.demote

        render json: ValidationError.new("fleet_members.demote", message: I18n.t("validation_error.fleet_memberships.demote_not_permitted")), status: :bad_request
      end

      def destroy
        return if @member.destroy

        render json: ValidationError.new("fleet_members.destroy", errors: @member.errors), status: :bad_request
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end

      private def set_member
        @member = @fleet.fleet_memberships
          .includes(:user)
          .joins(:user)
          .find_by!(users: {normalized_username: params[:username].downcase})

        authorize! @member
      end
    end
  end
end
