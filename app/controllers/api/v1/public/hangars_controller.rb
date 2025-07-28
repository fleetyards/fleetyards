# frozen_string_literal: true

module Api
  module V1
    module Public
      class HangarsController < ::Api::PublicBaseController
        include HangarFiltersConcern

        after_action -> { pagination_header(:vehicles) }, only: %i[show]

        def show
          user = User.find_by!(normalized_username: params.fetch(:username, "").downcase)

          unless user.public_hangar?
            not_found
            return
          end

          vehicle_query_params["sorts"] = sorting_params(Vehicle)

          scope = user.vehicles
            .purchased
            .public

          scope = will_it_fit?(scope) if vehicle_query_params["will_it_fit"].present?

          @q = scope.ransack(vehicle_query_params)

          result = @q.result(distinct: true)
            .includes(:model)
            .joins(:model)

          @vehicles = result_with_pagination(result, per_page(Vehicle))
        end

        def embed
          if !(request.referrer || "").include?(FRONTEND_DOMAIN) && !request.referrer.blank?
            ahoy.track "hangar_embedding", request.path_parameters
          end

          usernames = params.fetch(:usernames, []).map(&:downcase)
          user_ids = User.where(normalized_username: usernames, public_hangar: true).pluck(:id)

          vehicle_query_params["sorts"] = sorting_params(Vehicle, ["model_name asc"])

          @q = Vehicle.where(user_id: user_ids)
            .public
            .purchased
            .ransack(vehicle_query_params)

          @vehicles = @q.result(distinct: true)
            .includes(:model)
            .joins(:model)
        end
      end
    end
  end
end
