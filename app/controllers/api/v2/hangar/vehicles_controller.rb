# frozen_string_literal: true

require 'hangar_importer'

module Api
  module V2
    module Hangar
      class VehiclesController < ::Api::V2::BaseController
        def index
          authorize! :index, :api_hangar

          scope = current_user.vehicles.visible

          if price_range.present?
            vehicle_query_params['sorts'] = 'model_price asc'
            scope = scope.includes(:model).where(models: { price: price_range })
          end

          if pledge_price_range.present?
            vehicle_query_params['sorts'] = 'model_last_pledge_price asc'
            scope = scope.includes(:model).where(models: { last_pledge_price: pledge_price_range })
          end

          scope = loaner_included?(scope)

          vehicle_query_params['sorts'] = sort_by_name(['flagship desc', 'purchased desc', 'name asc', 'model_name asc'], 'model_name asc')

          @q = scope.ransack(vehicle_query_params)

          result = @q.result(distinct: true)
            .includes(:vehicle_upgrades, :model_paint, :model_upgrades, model: [:manufacturer])
            .joins(model: [:manufacturer])

          @vehicles = result_with_pagination(result, per_page(Vehicle))
        end

        def export
          authorize! :index, :api_hangar

          scope = current_user.vehicles.visible

          scope = loaner_included?(scope)

          vehicle_query_params['sorts'] = 'model_name asc'

          @q = scope.ransack(vehicle_query_params)

          @vehicles = @q.result(distinct: true)
            .includes(model: [:manufacturer])
            .joins(model: [:manufacturer])
        end

        def import
          authorize! :index, :api_hangar

          import_data = JSON.parse(params[:import].read)

          render json: ValidationError.new('vehicle.import', message: I18n.t('messages.hangar_import.no_data')), status: :bad_request if import_data.blank?

          @response = ::HangarImporter.new(import_data).run(current_user.id)
        rescue JSON::ParserError => e
          render json: ValidationError.new('vehicle.import', message: e), status: :bad_request
        end

        def hangar_items
          authorize! :index, :api_hangar
          model_ids = current_user.vehicles
            .where(loaner: false)
            .visible
            .pluck(:model_id)
          @models = Model.where(id: model_ids).order(name: :asc).pluck(:slug)
        end

        def hangar
          authorize! :index, :api_hangar
          @vehicles = current_user.vehicles.where(loaner: false).visible
        end

        def create
          @vehicle = Vehicle.new(
            vehicle_params.merge(public: true)
          )
          authorize! :create, vehicle

          if vehicle.save
            render status: :created
          else
            render json: ValidationError.new('vehicle.create', errors: @vehicle.errors), status: :bad_request
          end
        end

        def update
          authorize! :update, vehicle

          vehicle.vehicle_modules.destroy_all unless vehicle_params[:model_module_ids].nil?
          vehicle.vehicle_upgrades.destroy_all unless vehicle_params[:model_upgrade_ids].nil?
          vehicle.task_forces.destroy_all unless vehicle_params[:hangar_group_ids].nil?

          return if vehicle.update(vehicle_params)

          render json: ValidationError.new('vehicle.update', errors: @vehicle.errors), status: :bad_request
        end

        def update_bulk
          authorize! :update_bulk, :api_hangar

          errors = []

          Vehicle.transaction do
            scope = current_user.vehicles.where(id: params[:ids])

            scope.find_each do |vehicle|
              vehicle.task_forces.destroy_all unless vehicle_params[:hangar_group_ids].nil?

              next if vehicle.update(vehicle_bulk_params)

              errors << vehicle.errors
            end
          end

          return if errors.blank?

          render json: ValidationError.new('vehicle.bulk_update', errors: errors), status: :bad_request
        end

        def destroy
          authorize! :destroy, vehicle

          return if vehicle.destroy

          render json: ValidationError.new('vehicle.destroy', errors: @vehicle.errors), status: :bad_request
        end

        def destroy_bulk
          authorize! :destroy_bulk, :api_hangar

          Vehicle.transaction do
            scope = current_user.vehicles.where(id: params[:ids])

            # rubocop:disable Rails/SkipsModelValidations
            scope.update_all(notify: false)
            # rubocop:enable Rails/SkipsModelValidations

            vehicle_ids = scope.pluck(:id)

            VehicleUpgrade.where(vehicle_id: vehicle_ids).delete_all
            VehicleModule.where(vehicle_id: vehicle_ids).delete_all
            Vehicle.where(id: vehicle_ids).delete_all
          end
        end

        def destroy_all
          authorize! :destroy_all, :api_hangar

          Vehicle.transaction do
            # rubocop:disable Rails/SkipsModelValidations
            current_user.vehicles.update_all(notify: false)
            # rubocop:enable Rails/SkipsModelValidations

            vehicle_ids = current_user.vehicle_ids

            VehicleUpgrade.where(vehicle_id: vehicle_ids).delete_all
            VehicleModule.where(vehicle_id: vehicle_ids).delete_all
            Vehicle.where(id: vehicle_ids).delete_all
          end
        end

        def check_serial
          authorize! :check_serial, :api_vehicles

          render json: { serialTaken: current_user.vehicles.visible.exists?(serial: vehicle_params[:serial].upcase) }
        end

        private def vehicle
          @vehicle ||= Vehicle.find(params[:id])
        end
        helper_method :vehicle

        private def vehicle_params
          @vehicle_params ||= params.transform_keys(&:underscore)
            .permit(
              :name, :serial, :model_id, :purchased, :name_visible, :public, :sale_notify, :flagship, :model_paint_id,
              hangar_group_ids: [], model_module_ids: [], model_upgrade_ids: [], alternative_names: []
            ).merge(user_id: current_user.id)
        end

        private def vehicle_bulk_params
          @vehicle_bulk_params ||= params.transform_keys(&:underscore)
            .permit(
              :purchased, :public, hangar_group_ids: []
            ).merge(user_id: current_user.id)
        end

        private def price_range
          @price_range ||= price_in.map do |prices|
            gt_price, lt_price = prices.split('-')
            gt_price = if gt_price.blank?
                         0
                       else
                         gt_price.to_i
                       end
            lt_price = if lt_price.blank?
                         Float::INFINITY
                       else
                         lt_price.to_i
                       end
            (gt_price...lt_price)
          end
        end

        private def pledge_price_range
          @pledge_price_range ||= pledge_price_in.map do |prices|
            gt_price, lt_price = prices.split('-')
            gt_price = if gt_price.blank?
                         0
                       else
                         gt_price.to_i
                       end
            lt_price = if lt_price.blank?
                         Float::INFINITY
                       else
                         lt_price.to_i
                       end
            (gt_price...lt_price)
          end
        end

        private def pledge_price_in
          pledge_price_in = vehicle_query_params.delete('pledge_price_in')
          pledge_price_in = pledge_price_in.to_s.split unless pledge_price_in.is_a?(Array)
          pledge_price_in
        end

        private def price_in
          price_in = vehicle_query_params.delete('price_in')
          price_in = price_in.to_s.split unless price_in.is_a?(Array)
          price_in
        end

        private def loaner_included?(scope)
          if vehicle_query_params['loaner_eq'].blank?
            scope = scope.where(loaner: false)
          elsif vehicle_query_params['loaner_eq'] == 'true'
            vehicle_query_params.delete('loaner_eq')
          else
            scope = scope.where(loaner: true)
          end

          scope
        end

        private def vehicle_query_params
          @vehicle_query_params ||= query_params(
            :name_cont, :model_name_or_model_description_cont, :on_sale_eq, :purchased_eq, :public_eq,
            :length_gteq, :length_lteq, :price_gteq, :price_lteq, :pledge_price_gteq,
            :pledge_price_lteq, :loaner_eq,
            manufacturer_in: [], classification_in: [], focus_in: [],
            size_in: [], price_in: [], pledge_price_in: [],
            production_status_in: [], hangar_groups_in: [], hangar_groups_not_in: []
          )
        end
      end
    end
  end
end
