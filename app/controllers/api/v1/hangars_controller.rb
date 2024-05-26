# frozen_string_literal: true

module Api
  module V1
    class HangarsController < ::Api::BaseController
      include HangarFiltersConcern

      after_action -> { pagination_header(:vehicles) }, only: %i[show]

      def show
        authorize! :show, :api_hangar
        scope = current_user.vehicles.visible.purchased

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

        vehicle_query_params["sorts"] = sorting_params(Vehicle)

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
          current_user.vehicles.purchased.update_all(notify: false)
          # rubocop:enable Rails/SkipsModelValidations

          vehicle_ids = current_user.vehicles.purchased.pluck(:id)

          VehicleUpgrade.where(vehicle_id: vehicle_ids).delete_all
          VehicleModule.where(vehicle_id: vehicle_ids).delete_all
          Vehicle.where(id: vehicle_ids).delete_all
        end
      end

      def import
        authorize! :update, :api_hangar

        import = Imports::HangarImport.new(import_params.merge(user_id: current_user.id))

        unless import.save
          render json: ValidationError.new("hangar.import", errors: import.errors), status: :bad_request
          return
        end

        if import.import_data.blank?
          render json: {code: "hangar.import", message: I18n.t("errors.messages.hangar.import.no_data")}, status: :bad_request
          return
        end

        @response = ::HangarImporter.new(import).run
      rescue JSON::ParserError => e
        render json: ValidationError.new("hangar.import", message: e), status: :bad_request
      end

      def export
        authorize! :show, :api_hangar

        scope = current_user.vehicles.visible.purchased

        scope = loaner_included?(scope)

        vehicle_query_params["sorts"] = "model_name asc"

        @q = scope.ransack(vehicle_query_params)

        @vehicles = @q.result(distinct: true)
          .includes(model: [:manufacturer])
          .joins(model: [:manufacturer])
      end

      def sync_rsi_hangar
        authorize! :update, :api_hangar

        render json: ValidationError.new("vehicle.sync", message: I18n.t("messages.hangar_sync.no_data")), status: :bad_request if params[:items].blank?

        @response = ::HangarSync.new(sync_params[:items].to_a.map(&:to_h)).run(current_user.id)
      end

      def items
        authorize! :show, :api_hangar
        model_ids = current_user.vehicles
          .where(loaner: false)
          .visible
          .purchased
          .pluck(:model_id)
        @models = Model.where(id: model_ids).order(name: :asc).pluck(:slug)
      end

      def move_all_ingame_to_wishlist
        authorize! :update_bulk, :api_hangar

        errors = []

        Vehicle.transaction do
          scope = current_user.vehicles.purchased.where(bought_via: :ingame)

          scope.find_each do |vehicle|
            next if vehicle.update(wanted: true)

            errors << vehicle.errors
          end
        end

        return if errors.blank?

        render json: ValidationError.new("vehicle.move_all_ingame_to_wish_list", errors:), status: :bad_request
      end

      private def import_params
        @import_params ||= params.permit(:import)
      end

      private def sync_params
        @sync_params ||= params.permit(items: [:id, :name, :image, :type, :custom_name])
      end
    end
  end
end
