# frozen_string_literal: true

module Api
  module V1
    class FleetMembershipsController < ::Api::V1::BaseController
      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t('messages.record_not_found.fleet', slug: params[:slug]))
      end

      def create
        user = User.where(['lower(username) = :value', { value: params[:username].downcase }]).first!

        @member = fleet.fleet_memberships.new(user_id: user.id, role: :member)

        authorize! :create, member

        return if member.save

        render json: ValidationError.new('fleet_memberships.create', member.errors), status: :bad_request
      end

      def accept_invite
        authorize! :accept, my_membership

        return if my_membership.update(accepted_at: Time.zone.now)

        render json: ValidationError.new('fleet_memberships.accept', my_membership.errors), status: :bad_request
      end

      def decline_invite
        authorize! :accept, my_membership

        return if my_membership.update(declined_at: Time.zone.now)

        render json: ValidationError.new('fleet_memberships.accept', my_membership.errors), status: :bad_request
      end

      def promote
        authorize! :promote, member

        return if member.promote

        render json: ValidationError.new('fleet_memberships.promote', member.errors), status: :bad_request
      end

      def demote
        authorize! :demote, member

        return if member.demote

        render json: ValidationError.new('fleet_memberships.demote', member.errors), status: :bad_request
      end

      def destroy
        authorize! :destroy, member

        return if member.destroy

        render json: ValidationError.new('fleet_memberships.destroy', member.errors), status: :bad_request
      end

      def leave
        authorize! :destroy, my_membership

        return if my_membership.destroy

        render json: ValidationError.new('fleet_memberships.destroy', my_membership.errors), status: :bad_request
      end

      private def fleet
        @fleet ||= current_user.fleets.where(slug: params[:fleet_slug]).first!
      end

      private def member
        @member ||= fleet.fleet_memberships
                         .includes(:user)
                         .joins(:user)
                         .where(users: { username: params[:username] })
                         .first!
      end

      private def my_membership
        @my_membership ||= fleet.fleet_memberships
                                .includes(:user)
                                .joins(:user)
                                .where(user_id: current_user.id)
                                .first!
      end
    end
  end
end
