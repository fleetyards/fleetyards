# frozen_string_literal: true

module Api
  module V1
    module Public
      class WishlistsController < ::Api::PublicBaseController
        include HangarFiltersConcern

        after_action -> { pagination_header(:vehicles) }, only: %i[show]

        def show
          user = User.find_by!(normalized_username: params.fetch(:username, "").downcase)

          unless user.public_wishlist?
            not_found
            return
          end

          vehicle_query_params["sorts"] = sorting_params(Vehicle, ["name asc", "model_name asc"])

          scope = user.vehicles
            .wanted

          scope = will_it_fit?(scope) if vehicle_query_params["will_it_fit"].present?

          @q = scope.ransack(vehicle_query_params)

          result = @q.result(distinct: true)
            .includes(:model)
            .joins(:model)

          @vehicles = result_with_pagination(result, per_page(Vehicle))
        end
      end
    end
  end
end
