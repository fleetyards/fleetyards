# frozen_string_literal: true

module Api
  module V1
    class FleetDiscordRoleMappingsController < ::Api::BaseController
      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t("messages.record_not_found.fleet", slug: params[:fleet_slug]))
      end

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[show]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[update]

      before_action :set_fleet

      def show
        authorize! notification_setting, with: FleetNotificationSettingPolicy

        @fleet_roles = @fleet.fleet_roles.ranked
      end

      # Ranks the request does not name keep their mapping. Each changed rank
      # re-syncs its own members once the transaction commits, so a rank named
      # twice is applied once, with its last value.
      def update
        authorize! notification_setting, with: FleetNotificationSettingPolicy, to: :update?

        invalid = nil
        FleetRole.transaction do
          mapping_params.index_by { |mapping| mapping[:fleet_role_id] }.each_value do |mapping|
            fleet_role = @fleet.fleet_roles.find(mapping[:fleet_role_id])
            next if fleet_role.update(discord_role_id: mapping[:discord_role_id])

            invalid = fleet_role
            raise ActiveRecord::Rollback
          end
        end

        if invalid
          render json: ValidationError.new("fleet_discord_role_mappings.update", errors: invalid.errors), status: :bad_request
        else
          @fleet_roles = @fleet.fleet_roles.ranked
          render :show
        end
      end

      # Which role each rank hands out is part of the fleet's Discord setup, so
      # it belongs to whoever manages that, not to whoever may rename ranks.
      private def notification_setting
        @fleet.fleet_notification_setting || FleetNotificationSetting.new(fleet: @fleet)
      end

      private def mapping_params
        params.permit(mappings: %i[fleet_role_id discord_role_id]).fetch(:mappings, [])
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])
        authorize! @fleet, to: :show?
      end
    end
  end
end
