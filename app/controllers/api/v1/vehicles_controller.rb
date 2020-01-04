# frozen_string_literal: true

module Api
  module V1
    class VehiclesController < ::Api::V1::BaseController
      include ChartHelper

      skip_authorization_check only: %i[public public_quick_stats public_fleetchart embed]
      before_action :authenticate_api_user!, except: %i[public public_quick_stats public_fleetchart embed]
      after_action -> { pagination_header(:vehicles) }, only: %i[index public]

      def index
        authorize! :index, :api_hangar
        scope = current_user.vehicles

        if price_range.present?
          vehicle_query_params['sorts'] = 'model_price asc'
          scope = scope.includes(:model).where(models: { price: price_range })
        end

        if pledge_price_range.present?
          vehicle_query_params['sorts'] = 'model_last_pledge_price asc'
          scope = scope.includes(:model).where(models: { last_pledge_price: pledge_price_range })
        end

        vehicle_query_params['sorts'] = sort_by_name(['flagship desc', 'purchased desc', 'name asc', 'model_name asc'], 'model_name asc')

        @q = scope.ransack(vehicle_query_params)

        @vehicles = @q.result(distinct: true)
                      .includes(:model)
                      .joins(:model)
                      .page(params[:page])
                      .per(per_page(Vehicle))
      end

      def export
        authorize! :index, :api_hangar

        respond_to do |format|
          format.csv do
            send_data current_user.vehicles.to_csv, filename: "fleetyards-#{current_user.username}-hangar-#{Time.zone.now.iso8601}.csv"
          end
          format.all do
            render status: :not_found
          end
        end
      end

      def fleetchart
        authorize! :index, :api_hangar
        @q = current_user.vehicles
                         .ransack(vehicle_query_params)

        @vehicles = @q.result(distinct: true)
                      .includes(:model)
                      .joins(:model)
                      .sort_by { |vehicle| [-vehicle.model.length, vehicle.model.name] }
      end

      def quick_stats
        authorize! :index, :api_hangar
        @q = current_user.vehicles
                         .ransack(vehicle_query_params)

        @q.sorts = ['model_classification asc']

        vehicles = @q.result
        models = vehicles.map(&:model)
        upgrades = vehicles.map(&:model_upgrades).flatten
        modules = vehicles.map(&:model_modules).flatten

        @quick_stats = OpenStruct.new(
          total: vehicles.count,
          classifications: models.map(&:classification).uniq.compact.map do |classification|
            OpenStruct.new(
              # rubocop:disable Performance/Count
              count: models.select { |model| model.classification == classification }.size,
              # rubocop:enable Performance/Count
              name: classification,
              label: classification.humanize
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
        models = []
        models = user.public_models.order(classification: :asc) if user.public_hangar?

        @quick_stats = OpenStruct.new(
          total: models.count,
          classifications: models.map(&:classification).uniq.compact.map do |classification|
            OpenStruct.new(
              count: models.where(classification: classification).count,
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
        model_ids = current_user.vehicles.pluck(:model_id)
        @models = Model.where(id: model_ids).order(name: :asc).pluck(:slug)
      end

      def hangar
        authorize! :index, :api_hangar
        @vehicles = current_user.vehicles
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

        vehicle.vehicle_modules.destroy_all if vehicle_params[:model_module_ids].present?
        vehicle.vehicle_upgrades.destroy_all if vehicle_params[:model_upgrade_ids].present?

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
                  :name, :model_id, :purchased, :name_visible, :public, :sale_notify, :flagship,
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

      private def vehicle_query_params
        @vehicle_query_params ||= query_params(
          :name_cont, :model_name_or_model_description_cont, :on_sale_eq, :purchased_eq, :public_eq,
          :length_gteq, :length_lteq, :price_gteq, :price_lteq, :pledge_price_gteq,
          :pledge_price_lteq,
          manufacturer_in: [], classification_in: [], focus_in: [],
          size_in: [], price_in: [], pledge_price_in: [],
          production_status_in: [], hangar_groups_in: [], hangar_groups_not_in: []
        )
      end
    end
  end
end
