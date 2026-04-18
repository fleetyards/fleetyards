# frozen_string_literal: true

module Api
  module V1
    class OmniauthConnectionsController < ::Api::BaseController
      def destroy
        connection = current_resource_owner.omniauth_connections.find_by!(provider: params[:provider])

        authorize! connection

        if current_resource_owner.oauth_only? && current_resource_owner.omniauth_connections.count <= 1
          render json: {code: "omniauth_connection.destroy.last_connection", message: I18n.t("messages.omniauth_connection.destroy.last_connection")}, status: :forbidden
          return
        end

        connection.destroy!

        @user = current_resource_owner.reload

        render "api/v1/users/me"
      end
    end
  end
end
