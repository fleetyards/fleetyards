# frozen_string_literal: true

module Api
  module V1
    class FleetsController < ::Api::V1::BaseController
      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t('messages.record_not_found.fleet', slug: params[:slug]))
      end

      def create
        user = User.find_by(username: params[:username])
        @member = fleet.fleet_memberships.new(user_id: user.id)
        authorize! :create, member

        return if member.save

        render json: ValidationError.new('fleet_memberships.create', member.errors), status: :bad_request
      end

      def accept
        authorize! :accept, member

        return if member.update(accepted: true)

        render json: ValidationError.new('fleet_memberships.accept', member.errors), status: :bad_request
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

      private def fleet
        @fleet ||= current_user.fleets.where(slug: params[:slug]).first!
      end

      private def member
        @member ||= fleet.fleet_memberships
                         .includes(:user)
                         .joins(:user)
                         .where(user: { username: params[:username] })
                         .first!
      end
    end
  end
end
