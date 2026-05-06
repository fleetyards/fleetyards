# frozen_string_literal: true

module Api
  module V1
    class FleetNotificationSettingsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[show]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[update]

      before_action :set_fleet
      before_action :set_setting

      def show
        authorize! @setting, with: FleetNotificationSettingPolicy
      end

      def update
        authorize! @setting, with: FleetNotificationSettingPolicy

        if @setting.update(setting_params)
          render :show
        else
          render json: ValidationError.new("fleet_notification_settings.update", errors: @setting.errors), status: :bad_request
        end
      end

      private def setting_params
        permitted = params.permit(
          :discord_guild_id,
          :discord_channel_id,
          :discord_webhook_url,
          enabled_in_app_events: [],
          enabled_discord_events: []
        ).to_h.symbolize_keys

        # Front-end sends an empty string when the admin clears the webhook;
        # treat that as "remove the encrypted value".
        permitted[:discord_webhook_url] = nil if permitted[:discord_webhook_url] == ""
        permitted
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])
        authorize! @fleet, to: :show?
      end

      private def set_setting
        @setting = @fleet.fleet_notification_setting ||
          @fleet.create_fleet_notification_setting!(
            enabled_in_app_events: FleetNotificationSetting::DEFAULT_IN_APP_EVENTS
          )
      end
    end
  end
end
