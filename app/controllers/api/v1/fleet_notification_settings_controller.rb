# frozen_string_literal: true

module Api
  module V1
    class FleetNotificationSettingsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[show discord_status]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[update]

      before_action :set_fleet
      before_action :set_setting

      def show
        authorize! @setting, with: FleetNotificationSettingPolicy
      end

      # Probes Discord to confirm the fleet's guild binding is reachable with
      # the configured bot token. Returns a small status object the settings
      # page renders as a green/red pill.
      def discord_status
        authorize! @setting, with: FleetNotificationSettingPolicy, to: :show?

        render json: discord_status_payload.merge(installUrl: ::Discord::ApiClient.install_url)
      end

      private def discord_status_payload
        unless ::Discord::ApiClient.configured?
          return {ok: false, code: "missing_token", message: "Discord bot token is not configured server-side"}
        end

        if @setting.discord_guild_id.blank?
          return {ok: false, code: "missing_guild", message: "No Discord server linked to this fleet"}
        end

        begin
          guild = ::Discord::ApiClient.new.get_guild(@setting.discord_guild_id)
          {ok: true, guildId: guild["id"], guildName: guild["name"]}
        rescue ::Discord::ApiClient::Error => e
          code = case e.status
          when 401 then "invalid_token"
          when 403 then "bot_not_in_guild"
          when 404 then "guild_not_found"
          else "discord_error"
          end
          {ok: false, code: code, status: e.status, message: e.message}
        end
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
