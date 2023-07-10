# frozen_string_literal: true

module Api
  module V1
    module Public
      class HangarsController < ::Api::PublicBaseController
        include HangarFiltersConcern

        after_action -> { pagination_header(:vehicles) }, only: %i[show]

        def show
          user = User.find_by!("lower(username) = ?", params.fetch(:username, "").downcase)

          unless user.public_hangar?
            not_found
            return
          end

          vehicle_query_params["sorts"] = sort_by_name(["flagship desc", "name asc", "model_name asc"], "model_name asc")

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
          usernames = params.fetch(:usernames, []).map(&:downcase)
          user_ids = User.where("lower(username) IN (?)", usernames)
            .where(public_hangar: true)
            .pluck(:id)

          vehicle_query_params["sorts"] = sort_by_name(["model_name asc"], "model_name asc")

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
