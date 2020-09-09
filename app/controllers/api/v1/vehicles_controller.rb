# frozen_string_literal: true

require 'hangar_importer'

module Api
  module V1
    class VehiclesController < ::Api::BaseController
      include ChartHelper

      skip_authorization_check only: %i[public public_quick_stats public_fleetchart embed]
      before_action :authenticate_user!, except: %i[public public_quick_stats public_fleetchart embed]
      after_action -> { pagination_header(:vehicles) }, only: %i[index public]

      def index
        authorize! :index, :api_hangar
        scope = current_user.vehicles.visible

        Rails.logger.debug current_user.username.to_yaml

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

        @vehicles = @q.result(distinct: true)
                      .includes(model: [:manufacturer])
                      .joins(model: [:manufacturer])
                      .page(params[:page])
                      .per(per_page(Vehicle))
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

        @response = ::HangarImporter.new(JSON.parse(params[:import].read)).run(current_user.id)
      rescue JSON::ParserError => e
        render json: ValidationError.new('vehicle.import', e), status: :bad_request
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

      def fleetchart
        authorize! :index, :api_hangar
        scope = current_user.vehicles.visible

        scope = loaner_included?(scope)

        @q = scope.ransack(vehicle_query_params)

        @vehicles = @q.result(distinct: true)
                      .includes(model: [:manufacturer])
                      .joins(model: [:manufacturer])
                      .sort_by { |vehicle| [-vehicle.model.length, vehicle.model.name] }
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def quick_stats
        authorize! :index, :api_hangar
        scope = current_user.vehicles.visible.includes(:vehicle_upgrades, :model_upgrades, :vehicle_modules, :model_modules, :model)

        scope = loaner_included?(scope)

        @q = scope.ransack(vehicle_query_params)

        @q.sorts = ['model_classification asc']

        vehicles = @q.result
        models = vehicles.map(&:model)
        upgrades = vehicles.map(&:model_upgrades).flatten
        modules = vehicles.map(&:model_modules).flatten

        @quick_stats = OpenStruct.new(
          total: vehicles.count,
          classifications: Model.classifications.map do |classification|
            OpenStruct.new(
              count: models.count { |model| model.classification == classification },

              name: classification,
              label: classification.humanize
            )
          end,
          groups: HangarGroup.where(user: current_user).order([{ sort: :asc, name: :asc }]).map do |group|
            OpenStruct.new(
              count: group.vehicles.where(id: vehicles.map(&:id)).size,
              id: group.id,
              slug: group.slug
            )
          end,
          metrics: {
            total_money: models.map(&:last_pledge_price).sum(&:to_i) + modules.map(&:pledge_price).sum(&:to_i) + upgrades.map(&:pledge_price).sum(&:to_i),
            total_min_crew: models.map(&:min_crew).sum(&:to_i),
            total_max_crew: models.map(&:max_crew).sum(&:to_i),
            total_cargo: models.map(&:cargo).sum(&:to_i)
          }
        )
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def public
        user = User.find_by!('lower(username) = ?', params.fetch(:username, '').downcase)

        vehicle_query_params['sorts'] = sort_by_name(['flagship desc', 'name asc', 'model_name asc'], 'model_name asc')

        @q = user.vehicles
                 .public
                 .ransack(vehicle_query_params)

        @vehicles = @q.result(distinct: true)
                      .includes(:model)
                      .joins(:model)
                      .page(params[:page])
                      .per(per_page(Vehicle))
      end

      def public_fleetchart
        user = User.find_by!('lower(username) = ?', params.fetch(:username, '').downcase)

        @q = user.vehicles
                 .visible
                 .public
                 .ransack(vehicle_query_params)

        @vehicles = []
        return unless user.public_hangar?

        @vehicles = @q.result(distinct: true)
                      .includes(:model)
                      .joins(:model)
                      .sort_by { |vehicle| [-vehicle.model.length, vehicle.model.name] }
      end

      def public_quick_stats
        user = User.find_by!('lower(username) = ?', params.fetch(:username, '').downcase)

        vehicles = user.vehicles
                       .public
                       .where(loaner: false)
                       .includes(:model)
                       .order('models.classification asc')

        models = vehicles.map(&:model)

        @quick_stats = OpenStruct.new(
          total: vehicles.count,
          classifications: Model.classifications.map do |classification|
            OpenStruct.new(
              count: models.count { |model| model.classification == classification },

              name: classification,
              label: classification.humanize
            )
          end
        )
      end

      def embed
        usernames = params.fetch(:usernames, []).map(&:downcase)
        user_ids = User.where('lower(username) IN (?)', usernames)
                       .where(public_hangar: true)
                       .pluck(:id)

        vehicle_query_params['sorts'] = sort_by_name(['model_name asc'], 'model_name asc')

        @q = Vehicle.where(user_id: user_ids)
                    .public
                    .ransack(vehicle_query_params)

        @vehicles = @q.result(distinct: true)
                      .includes(:model)
                      .joins(:model)

        render 'api/v1/vehicles/public'
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
        @vehicle = Vehicle.new(vehicle_params)
        authorize! :create, vehicle

        if vehicle.save
          render status: :created
        else
          render json: ValidationError.new('vehicle.create', @vehicle.errors), status: :bad_request
        end
      end

      def update
        authorize! :update, vehicle

        vehicle.vehicle_modules.destroy_all unless vehicle_params[:model_module_ids].nil?
        vehicle.vehicle_upgrades.destroy_all unless vehicle_params[:model_upgrade_ids].nil?
        vehicle.task_forces.destroy_all if vehicle_params[:hangar_group_ids].blank?

        return if vehicle.update(vehicle_params)

        render json: ValidationError.new('vehicle.update', @vehicle.errors), status: :bad_request
      end

      def destroy
        authorize! :destroy, vehicle

        return if vehicle.destroy

        render json: ValidationError.new('vehicle.destroy', @vehicle.errors), status: :bad_request
      end

      def models_by_size
        authorize! :read, :api_stats

        models_by_size = transform_for_pie_chart(
          current_user.models.visible.active
               .group(:size).count
               .map { |label, count| { (label.present? ? label.humanize : I18n.t('labels.unknown')) => count } }
               .reduce(:merge) || []
        )

        render json: models_by_size.to_json
      end

      def models_by_production_status
        authorize! :read, :api_stats

        models_by_production_status = transform_for_pie_chart(
          current_user.models.visible.active
               .group(:production_status).count
               .map { |label, count| { (label.present? ? label.humanize : I18n.t('labels.unknown')) => count } }
               .reduce(:merge) || []
        )

        render json: models_by_production_status.to_json
      end

      def models_by_manufacturer
        authorize! :read, :api_stats

        models_by_manufacturer = transform_for_pie_chart(
          current_user.manufacturers.uniq
              .map { |m| { m.name => m.models.where(id: current_user.models.pluck(:id)).count } }
              .reduce(:merge) || []
        )

        render json: models_by_manufacturer.to_json
      end

      def models_by_classification
        authorize! :read, :api_stats

        models_by_classification = transform_for_pie_chart(
          current_user.models.visible.active
               .group(:classification).count
               .map { |label, count| { (label.present? ? label.humanize : I18n.t('labels.unknown')) => count } }
               .reduce(:merge) || []
        )

        render json: models_by_classification.to_json
      end

      private def vehicle
        @vehicle ||= Vehicle.find(params[:id])
      end
      helper_method :vehicle

      private def vehicle_params
        @vehicle_params ||= begin
          params.transform_keys(&:underscore)
                .permit(
                  :name, :model_id, :purchased, :name_visible, :public, :sale_notify, :flagship, :model_paint_id,
                  hangar_group_ids: [], model_module_ids: [], model_upgrade_ids: []
                ).merge(user_id: current_user.id)
        end
      end

      private def price_range
        @price_range ||= begin
          price_in.map do |prices|
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
      end

      private def pledge_price_range
        @pledge_price_range ||= begin
          pledge_price_in.map do |prices|
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
