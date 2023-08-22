# frozen_string_literal: true

module Api
  module V1
    class WishlistsController < ::Api::BaseController
      include HangarFiltersConcern

      after_action -> { pagination_header(:vehicles) }, only: %i[show]

      def show
        authorize! :show, :api_hangar
        scope = current_user.vehicles.visible.wanted

        if price_range.present?
          vehicle_query_params["sorts"] = "model_price asc"
          scope = scope.includes(:model).where(models: {price: price_range})
        end

        if pledge_price_range.present?
          vehicle_query_params["sorts"] = "model_last_pledge_price asc"
          scope = scope.includes(:model).where(models: {last_pledge_price: pledge_price_range})
        end

        scope = loaner_included?(scope)
        scope = will_it_fit?(scope) if vehicle_query_params["will_it_fit"].present?

        vehicle_query_params["sorts"] = sorting_params(Vehicle, ["name asc", "model_name asc"])

        @q = scope.ransack(vehicle_query_params)

        result = @q.result(distinct: true)
          .includes(:vehicle_upgrades, :model_paint, :model_upgrades, model: [:manufacturer])
          .joins(model: [:manufacturer])

        @vehicles = result_with_pagination(result, per_page(Vehicle))
      end

      def destroy
        authorize! :destroy, :api_hangar

        Vehicle.transaction do
          # rubocop:disable Rails/SkipsModelValidations
          current_user.vehicles.wanted.update_all(notify: false)
          # rubocop:enable Rails/SkipsModelValidations

          vehicle_ids = current_user.vehicles.wanted.pluck(:id)

          VehicleUpgrade.where(vehicle_id: vehicle_ids).delete_all
          VehicleModule.where(vehicle_id: vehicle_ids).delete_all
          Vehicle.where(id: vehicle_ids).delete_all
        end
      end

      def export
        authorize! :show, :api_hangar

        scope = current_user.vehicles.visible.wanted

        scope = loaner_included?(scope)

        vehicle_query_params["sorts"] = "model_name asc"

        @q = scope.ransack(vehicle_query_params)

        @vehicles = @q.result(distinct: true)
          .includes(model: [:manufacturer])
          .joins(model: [:manufacturer])
      end

      def items
        authorize! :show, :api_hangar
        model_ids = current_user.vehicles
          .where(loaner: false)
          .visible
          .wanted
          .pluck(:model_id)
        @models = Model.where(id: model_ids).order(name: :asc).pluck(:slug)
      end
    end
  end
end
