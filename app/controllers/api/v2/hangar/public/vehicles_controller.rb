# frozen_string_literal: true

module Api
  module V2
    module Hangar
      module Public
        class VehiclesController < ::Api::V2::BaseController
          before_action :authenticate_user!, only: []

          def index
            user = User.find_by!("lower(username) = ?", params.fetch(:username, "").downcase)

            unless user.public_hangar?
              not_found
              return
            end

            vehicle_query_params["sorts"] = sort_by_name(["flagship desc", "name asc", "model_name asc"], "model_name asc")

            @q = user.vehicles
              .public
              .ransack(vehicle_query_params)

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
              .ransack(vehicle_query_params)

            @vehicles = @q.result(distinct: true)
              .includes(:model)
              .joins(:model)

            render "api/v2/hangar/public/vehicles/index"
          end

          private def vehicle_query_params
            @vehicle_query_params ||= query_params(
              :name_cont, :model_name_or_model_description_cont, :on_sale_eq, :length_gteq, :length_lteq,
              manufacturer_in: [], classification_in: [], focus_in: [],
              size_in: [], production_status_in: [], hangar_groups_in: [], hangar_groups_not_in: []
            )
          end
        end
      end
    end
  end
end
