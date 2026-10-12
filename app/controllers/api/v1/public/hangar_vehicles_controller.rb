# frozen_string_literal: true

module Api
  module V1
    module Public
      # One ship of a public hangar, for a link that opens it -- a shared plaque.
      class HangarVehiclesController < ::Api::PublicBaseController
        include HangarShareTokenConcern

        before_action :set_user
        before_action :check_owner_feature

        def show
          @vehicle = @user.vehicles.purchased.public.find(params[:id])
        end

        private def set_user
          @user = User.find_by!(normalized_username: params[:hangar_username].downcase)

          authorize! @user, to: :show?, with: ::Public::UserPolicy
        end

        # The owner shares the plaque, so it is the owner's flag that decides,
        # not the visitor's -- who may well be signed out.
        private def check_owner_feature
          return if Flipper.enabled?(:vehicle_overview, @user)

          render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
        end
      end
    end
  end
end
