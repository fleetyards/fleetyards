# frozen_string_literal: true

module Api
  module V1
    class FleetMembersController < ::Api::V1::BaseController
      before_action :authenticate_api_user!, only: %i[join accept]

      def join
        authorize! :join, :api_fleets

        membership = fleet.pending_members.create(user_id: current_user.id)

        if membership.errors.blank?
          render json: { code: 'fleet.join', message: I18n.t('messages.fleet.join.success') }, status: :created
        else
          render json: ValidationError.new("fleet.join", @membership.errors), status: :bad_request
        end
      end

      def accept
        authorize! :accept, :api_my_fleets

        pending_member = admin_fleet.pending_members
                                    .includes(:user)
                                    .find_by(users: { username: params[:username] })

        if pending_member.present? && pending_member.approve
          render json: { code: 'fleet.accept', message: I18n.t('messages.fleet.accept.success') }, status: :created
        else
          render json: { code: 'fleet.accept', message: I18n.t('messages.fleet.accept.failure') }, status: :bad_request
        end
      end

      def decline
        authorize! :decline, :api_my_fleets

        pending_member = admin_fleet.pending_members
                                    .includes(:user)
                                    .find_by(users: { username: params[:username] })

        if pending_member.present? && pending_member.destroy
          render json: { code: 'fleet.decline', message: I18n.t('messages.fleet.decline.success') }, status: :created
        else
          render json: { code: 'fleet.decline', message: I18n.t('messages.fleet.decline.failure') }, status: :bad_request
        end
      end

      def remove
        authorize! :remove, :api_my_fleets

        member = admin_fleet.members
                            .includes(:user)
                            .find_by(users: { username: params[:username] })

        if member.present? && current_user.id != member.user_id && member.destroy
          render json: { code: 'fleet.remove', message: I18n.t('messages.fleet.remove.success') }, status: :created
        else
          render json: { code: 'fleet.remove', message: I18n.t('messages.fleet.remove.failure') }, status: :bad_request
        end
      end

      def promote
        authorize! :promote, :api_my_fleets

        member = admin_fleet.members
                            .includes(:user)
                            .find_by(users: { username: params[:username] })

        if member.present? && member.promote
          render json: { code: 'fleet.promote', message: I18n.t('messages.fleet.promote.success') }, status: :created
        else
          render json: { code: 'fleet.promote', message: I18n.t('messages.fleet.promote.failure') }, status: :bad_request
        end
      end

      def demote
        authorize! :demote, :api_my_fleets

        member = admin_fleet.members
                            .includes(:user)
                            .find_by(users: { username: params[:username] })

        if member.present? && current_user.id != member.user_id && member.demote
          render json: { code: 'fleet.demote', message: I18n.t('messages.fleet.demote.success') }, status: :created
        else
          render json: { code: 'fleet.demote', message: I18n.t('messages.fleet.demote.failure') }, status: :bad_request
        end
      end

      private def fleet
        @fleet ||= Fleet.find_by!(sid: params[:fleet_sid])
      end

      private def admin_fleet
        Rails.logger.debug params.to_yaml
        @admin_fleet ||= current_user.admin_fleets.find_by!(sid: params[:fleet_sid])
      end
    end
  end
end
