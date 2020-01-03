# frozen_string_literal: true

module Api
  module V1
    class FleetsController < ::Api::V1::BaseController
      after_action -> { pagination_header(:vehicles) }, only: %i[vehicles]
      after_action -> { pagination_header(:models) }, only: %i[models]
      after_action -> { pagination_header(:members) }, only: %i[members]

      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t('messages.record_not_found.fleet', slug: params[:slug]))
      end

      def show
        authorize! :read, :api_fleet
        @fleet = Fleet.where(slug: params[:slug]).first!
      end

      def vehicles
        authorize! :show, fleet
        scope = fleet.public_vehicles

        if price_range.present?
          vehicle_query_params['sorts'] = 'model_price asc'
          scope = scope.includes(:model).where(models: { price: price_range })
        end

        if pledge_price_range.present?
          vehicle_query_params['sorts'] = 'model_last_pledge_price asc'
          scope = scope.includes(:model).where(models: { last_pledge_price: pledge_price_range })
        end

        vehicle_query_params['sorts'] = sort_by_name(['model_name asc'], 'model_name asc')

        @q = scope.ransack(vehicle_query_params)

        @vehicles = @q.result(distinct: true)
                      .includes(:model)
                      .joins(:model)
                      .page(params[:page])
                      .per(per_page(Vehicle))
      end

      def models
        authorize! :show, fleet
        scope = fleet.public_models

        if price_range.present?
          model_query_params['sorts'] = 'price asc'
          scope = scope.where(price: price_range)
        end

        if pledge_price_range.present?
          model_query_params['sorts'] = 'last_pledge_price asc'
          scope = scope.where(last_pledge_price: pledge_price_range)
        end

        model_query_params['sorts'] = sort_by_name(['name asc'], 'name asc')

        @q = scope.ransack(model_query_params)

        @models = @q.result(distinct: true)
                    .page(params[:page])
                    .per(per_page(Vehicle))
      end

      def members
        authorize! :show, fleet

        scope = fleet.fleet_memberships

        member_query_params['sorts'] = sort_by_name(['created_at desc', 'accepted_at desc'], 'user_username asc')

        @q = scope.ransack(member_query_params)

        @members = @q.result(distinct: true)
                     .includes(:user)
                     .joins(:user)
                     .page(params[:page])
                     .per(per_page(Vehicle))
      end

      def member_quick_stats
        authorize! :show, fleet
        @q = fleet.fleet_memberships.ransack(member_query_params)

        members = @q.result

        @quick_stats = OpenStruct.new(
          total: members.size,
          metrics: {
            total_admins: members.where(role: :admin).size,
            total_officers: members.where(role: :officer).size,
            total_members: members.where(role: :member).size
          }
        )
      end

      def create
        @fleet = Fleet.new(fleet_params.merge(created_by: current_user.id))
        authorize! :create, fleet

        return if fleet.save

        render json: ValidationError.new('create', fleet.errors), status: :bad_request
      end

      def update
        authorize! :update, fleet

        return if fleet.update(fleet_params)

        render json: ValidationError.new('update', fleet.errors), status: :bad_request
      end

      def destroy
        authorize! :destroy, fleet

        return if fleet.destroy

        render json: ValidationError.new('destroy', fleet.errors), status: :bad_request
      end

      def fleetchart
        authorize! :show, fleet
        @q = fleet.public_vehicles.ransack(vehicle_query_params)

        @vehicles = @q.result(distinct: true)
                      .includes(:model)
                      .joins(:model)
                      .sort_by { |vehicle| [-vehicle.model.length, vehicle.model.name] }
      end

      def quick_stats
        authorize! :show, fleet
        @q = fleet.public_vehicles.ransack(vehicle_query_params)

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
            total_members: fleet.fleet_memberships.size,
            total_money: models.map(&:last_pledge_price).sum(&:to_i) + modules.map(&:pledge_price).sum(&:to_i) + upgrades.map(&:pledge_price).sum(&:to_i),
            total_min_crew: models.map(&:min_crew).sum(&:to_i),
            total_max_crew: models.map(&:max_crew).sum(&:to_i),
            total_cargo: models.map(&:cargo).sum(&:to_i)
          }
        )
      end

      def models_by_size
        authorize! :show, fleet

        models_by_size = transform_for_pie_chart(
          fleet.public_models.visible.active
              .group(:size).count
              .map { |label, count| { (label.present? ? label.humanize : I18n.t('labels.unknown')) => count } }
              .reduce(:merge) || []
        )

        render json: models_by_size.to_json
      end

      def models_by_production_status
        authorize! :show, fleet

        models_by_production_status = transform_for_pie_chart(
          fleet.public_models.visible.active
              .group(:production_status).count
              .map { |label, count| { (label.present? ? label.humanize : I18n.t('labels.unknown')) => count } }
              .reduce(:merge) || []
        )

        render json: models_by_production_status.to_json
      end

      def models_by_manufacturer
        authorize! :show, fleet

        models_by_manufacturer = transform_for_pie_chart(
          fleet.manufacturers.uniq
              .map { |m| { m.name => m.models.where(id: fleet.public_models.pluck(:id)).count } }
              .reduce(:merge) || []
        )

        render json: models_by_manufacturer.to_json
      end

      def models_by_classification
        authorize! :show, fleet

        models_by_classification = transform_for_pie_chart(
          fleet.public_models.visible.active
              .group(:classification).count
              .map { |label, count| { (label.present? ? label.humanize : I18n.t('labels.unknown')) => count } }
              .reduce(:merge) || []
        )

        render json: models_by_classification.to_json
      end

      private def fleet
        @fleet ||= current_user.fleets.where(slug: params[:slug]).first!
      end

      private def fleet_params
        @fleet_params ||= params.transform_keys(&:underscore)
                                .permit(
                                  :name, :logo, :background_image, :public, :remove_logo,
                                  :remove_background
                                )
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

      private def member_query_params
        @member_query_params ||= query_params(
          :username_cont, sorts: [], role_in: []
        )
      end

      private def vehicle_query_params
        @vehicle_query_params ||= query_params(
          :model_name_cont, :model_name_or_model_description_cont, :on_sale_eq, :length_gteq, :length_lteq,
          :price_gteq, :price_lteq, :pledge_price_gteq, :pledge_price_lteq,
          manufacturer_in: [], classification_in: [], focus_in: [],
          size_in: [], price_in: [], pledge_price_in: [],
          production_status_in: [], sorts: []
        )
      end

      private def model_query_params
        @model_query_params ||= query_params(
          :name_cont, :description_cont, :name_or_description_cont, :on_sale_eq, :sorts,
          :length_gteq, :length_lteq, :price_gteq, :price_lteq, :pledge_price_gteq,
          :pledge_price_lteq, :will_it_fit, :search_cont,
          name_in: [], manufacturer_in: [], classification_in: [], focus_in: [],
          production_status_in: [], price_in: [], pledge_price_in: [], size_in: [], sorts: [],
          id_not_in: []
        )
      end
    end
  end
end
