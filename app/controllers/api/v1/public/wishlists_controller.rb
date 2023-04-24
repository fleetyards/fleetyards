
# frozen_string_literal: true

module Api
  module V1
    module Public
      class WishlistsController < ::Api::PublicBaseController
        include HangarFiltersConcern

        after_action -> { pagination_header(:vehicles) }, only: %i[show]

        def show
          user = User.find_by!("lower(username) = ?", params.fetch(:username, "").downcase)

          unless user.public_wishlist?
            not_found
            return
          end

          vehicle_query_params["sorts"] = sort_by_name(["name asc", "model_name asc"], "model_name asc")

          @q = user.vehicles
            .wanted
            .ransack(vehicle_query_params)

          result = @q.result(distinct: true)
            .includes(:model)
            .joins(:model)

          @vehicles = result_with_pagination(result, per_page(Vehicle))
        end
      end
    end
  end
end
