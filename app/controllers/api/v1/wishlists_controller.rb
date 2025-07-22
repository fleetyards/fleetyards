# frozen_string_literal: true

module Api
  module V1
    class WishlistsController < ::Api::BaseController
      include HangarFiltersConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?,
        only: %i[show export items]
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: :user_signed_in?,
        except: %i[show export items]

      after_action -> { pagination_header(:vehicles) }, only: %i[show]

      def show
        authorize! with: ::HangarPolicy

        scope = authorized_scope(Vehicle.all).visible.wanted

        if price_range.present?
          vehicle_query_params["sorts"] = "model_price asc"
          scope = scope.includes(:model).where(models: {price: price_range})
        end

        if pledge_price_range.present?
          vehicle_query_params["sorts"] = "model_pledge_price asc"
          scope = scope.includes(:model).where(models: {pledge_price: pledge_price_range})
        end

        scope = loaner_included?(scope)
        scope = will_it_fit?(scope) if vehicle_query_params["will_it_fit"].present?

        vehicle_query_params["sorts"] = sorting_params(Vehicle, vehicle_query_params["sorts"], ["name asc", "model_name asc"])

        @q = scope.ransack(vehicle_query_params)

        result = @q.result(distinct: true)
          .includes(:vehicle_upgrades, :model_paint, :model_upgrades, model: [:manufacturer])
          .joins(model: [:manufacturer])

        @vehicles = result_with_pagination(result, per_page(Vehicle))
      end

      def destroy
        authorize! with: ::HangarPolicy

        Vehicle.transaction do
          # rubocop:disable Rails/SkipsModelValidations
          authorized_scope(Vehicle.all).wanted.update_all(notify: false)
          # rubocop:enable Rails/SkipsModelValidations

          vehicle_ids = authorized_scope(Vehicle.all).wanted.pluck(:id)

          VehicleUpgrade.where(vehicle_id: vehicle_ids).delete_all
          VehicleModule.where(vehicle_id: vehicle_ids).delete_all
          Vehicle.where(id: vehicle_ids).delete_all
        end
      end

      def export
        authorize! with: ::HangarPolicy

        scope = authorized_scope(Vehicle.all).visible.wanted

        scope = loaner_included?(scope)

        vehicle_query_params["sorts"] = "model_name asc"

        @q = scope.ransack(vehicle_query_params)

        @vehicles = @q.result(distinct: true)
          .includes(model: [:manufacturer])
          .joins(model: [:manufacturer])
      end

      def items
        authorize! with: ::HangarPolicy

        model_ids = authorized_scope(Vehicle.all)
          .where(loaner: false)
          .visible
          .wanted
          .pluck(:model_id)
        @models = Model.where(id: model_ids).order(name: :asc).pluck(:slug)
      end
    end
  end
end
