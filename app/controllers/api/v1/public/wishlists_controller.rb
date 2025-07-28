# frozen_string_literal: true

module Api
  module V1
    module Public
      class WishlistsController < ::Api::PublicBaseController
        include HangarFiltersConcern

        before_action :set_user
        after_action -> { pagination_header(:vehicles) }, only: %i[show]

        def show
          vehicle_query_params["sorts"] = sorting_params(Vehicle, vehicle_query_params[:sorts], ["name asc", "model_name asc"])

          scope = @user.vehicles.wanted

          scope = will_it_fit?(scope) if vehicle_query_params["will_it_fit"].present?

          @q = scope.ransack(vehicle_query_params)

          result = @q.result(distinct: true)
            .includes(:model)
            .joins(:model)

          @vehicles = result_with_pagination(result, per_page(Vehicle))
        end

        private def set_user
          @user = User.find_by!(normalized_username: params.fetch(:username, "").downcase)

          authorize! @user, to: :wishlist?, with: ::Public::UserPolicy
        end
      end
    end
  end
end
