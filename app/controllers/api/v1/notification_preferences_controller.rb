# frozen_string_literal: true

module Api
  module V1
    class NotificationPreferencesController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "notifications", "notifications:read" },
        unless: :user_signed_in?,
        only: %i[index]
      before_action -> { doorkeeper_authorize! "notifications", "notifications:write" },
        unless: :user_signed_in?,
        only: %i[update]

      def index
        authorize! with: NotificationPreferencePolicy

        @notification_preferences = Notification.notification_types.keys.map do |type|
          NotificationPreference.for(user: current_user, type:)
        end
      end

      def update
        authorize! with: NotificationPreferencePolicy

        return not_found unless Notification.notification_types.key?(params[:id])

        @notification_preference = current_user.notification_preferences
          .find_or_initialize_by(notification_type: params[:id])

        if @notification_preference.update(notification_preference_params)
          render :show
        else
          render json: ValidationError.new("notification_preference", @notification_preference.errors), status: :bad_request
        end
      end

      private def notification_preference_params
        params.permit(:app, :mail, :push)
      end
    end
  end
end
