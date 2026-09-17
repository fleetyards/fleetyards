# frozen_string_literal: true

module Api
  module V1
    module Me
      # The fleet this account's donations support, chosen independently of any
      # donation.
      #
      # Separate from the nomination on a contribution because it answers a
      # question that arrives earlier: a donation is imported and matched days
      # after it is made, so the moment somebody is deciding -- just before they
      # pay -- is the one moment no contribution exists to hang the answer on.
      class SupportedFleetsController < ::Api::BaseController
        before_action :authenticate_user!, only: []
        before_action -> { doorkeeper_authorize! "user", "user:read" },
          unless: :user_signed_in?,
          only: %i[show]
        before_action -> { doorkeeper_authorize! "user", "user:write" },
          unless: :user_signed_in?,
          only: %i[update]

        before_action :check_fleet_subscriptions_feature

        skip_verify_authorized only: %i[show update]

        def show
          @user = current_resource_owner
          render :show
        end

        def update
          @user = current_resource_owner

          if @user.update(supported_fleet_params)
            render :show
          else
            render json: ValidationError.new("supporter_contributions.nominate",
              errors: @user.errors), status: :bad_request
          end
        end

        private def check_fleet_subscriptions_feature
          return if feature_enabled?("fleet_subscriptions")

          render json: {code: "forbidden", message: "This feature is not available"},
            status: :forbidden
        end

        private def supported_fleet_params
          {supported_fleet_id: params.permit(:fleet_id)[:fleet_id].presence}
        end
      end
    end
  end
end
