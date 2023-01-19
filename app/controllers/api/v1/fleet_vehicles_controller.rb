# frozen_string_literal: true

module Api
  module V1
    class FleetVehiclesController < ::Api::BaseController
      before_action :authenticate_user!, except: %i[
        public public_fleetchart public_model_counts embed
      ]

      after_action -> { pagination_header(%i[vehicles models]) }, only: %i[index public]

      def index
        authorize! :show, fleet

        scope = fleet.vehicles.includes(
          :model_paint, :vehicle_upgrades, :model_upgrades, :vehicle_modules, :model_modules,
          model: [:manufacturer]
        )

        scope = scope.where(loaner: loaner_included?)

        scope = scope.where(user_id: for_members) if for_members.present?

        if price_range.present?
          vehicle_query_params["sorts"] = "model_price asc"
          scope = scope.includes(:model).where(models: { price: price_range })
        end

        if pledge_price_range.present?
          vehicle_query_params["sorts"] = "model_last_pledge_price asc"
          scope = scope.includes(:model).where(models: { last_pledge_price: pledge_price_range })
        end

        vehicle_query_params["sorts"] = sort_by_name(["model_name asc"], "model_name asc")

        @q = scope.ransack(vehicle_query_params)

        if ActiveModel::Type::Boolean.new.cast(params["grouped"])
          model_ids = @q.result.pluck(:model_id)

          result = fleet.models
            .where(id: model_ids)
            .distinct
            .order(name: :asc)

          @models = result_with_pagination(result, per_page(Model))

          render "api/v1/fleet_vehicles/models"
        else
          result = @q.result(distinct: true).includes(:model).joins(:model)

          @vehicles = result_with_pagination(result, per_page(Vehicle))
        end
      end

      def export
        authorize! :show, fleet

        scope = fleet.vehicles.includes(:vehicle_upgrades, :vehicle_modules, model: [:manufacturer])

        scope = scope.where(loaner: loaner_included?)

        scope = scope.where(user_id: for_members) if for_members.present?

        vehicle_query_params["sorts"] = "model_name asc"

        @q = scope.ransack(vehicle_query_params)

        @vehicles = @q.result(distinct: true).includes(:model).joins(:model)
      end

      def model_counts
        authorize! :show, fleet

        scope = fleet.vehicles.includes(
          :model_paint, :vehicle_upgrades, :model_upgrades, :vehicle_modules, :model_modules,
          model: [:manufacturer]
        )

        scope = scope.where(loaner: loaner_included?)

        scope = scope.where(user_id: for_members) if for_members.present?

        scope = scope.includes(:model).where(models: { price: price_range }) if price_range.present?

        scope = scope.includes(:model).where(models: { last_pledge_price: pledge_price_range }) if pledge_price_range.present?

        @q = scope.ransack(vehicle_query_params)

        @model_counts = @q.result.includes(:model).joins(:model).group("models.slug").count
      end

      def public
        authorize! :read, :api_fleet

        @fleet = Fleet.find_by!(slug: params[:slug])

        unless fleet.public_fleet?
          @vehicles = Kaminari.paginate_array([]).page(params[:page]).per(per_page(Vehicle))
          return
        end

        scope = fleet.vehicles.includes(:model_paint, :vehicle_upgrades, :model_upgrades, :vehicle_modules, :model_modules, model: [:manufacturer])

        scope = scope.where(loaner: loaner_included?)

        vehicle_query_params["sorts"] = sort_by_name(["model_name asc"], "model_name asc")

        @q = scope.ransack(vehicle_query_params)

        if ActiveModel::Type::Boolean.new.cast(params["grouped"])
          model_ids = @q.result.pluck(:model_id)

          result = fleet.models
            .where(id: model_ids)
            .distinct
            .order(name: :asc)

          @models = result_with_pagination(result, per_page(Model))

          render "api/v1/fleet_vehicles/public_models"
        else
          result = @q.result(distinct: true)
            .includes(:model)
            .joins(:model)

          @vehicles = result_with_pagination(result, per_page(Vehicle))
        end
      end

      def public_model_counts
        authorize! :read, :api_fleet

        @fleet = Fleet.find_by!(slug: params[:slug])

        unless fleet.public_fleet?
          @vehicles = Kaminari.paginate_array([]).page(params[:page]).per(per_page(Vehicle))
          return
        end

        scope = fleet.vehicles.includes(:model_paint, :vehicle_upgrades, :model_upgrades, :vehicle_modules, :model_modules, model: [:manufacturer])

        @q = scope.ransack(vehicle_query_params)

        @model_counts = @q.result.includes(:model).joins(:model).group("models.slug").count
      end

      def embed
        authorize! :read, :api_fleet

        @fleet = Fleet.find_by!(slug: params[:slug])

        unless fleet.public_fleet?
          @vehicles = []
          return
        end

        scope = fleet.vehicles.includes(:model_paint, :vehicle_upgrades, :model_upgrades, :vehicle_modules, :model_modules, model: [:manufacturer])

        vehicle_query_params["sorts"] = sort_by_name(["model_name asc"], "model_name asc")

        @q = scope.ransack(vehicle_query_params)

        @vehicles = @q.result(distinct: true)
          .includes(:model)
          .joins(:model)
          .all
      end

      def fleetchart
        authorize! :show, fleet

        scope = fleet.vehicles.includes(:model_paint, :vehicle_upgrades, :model_upgrades, :vehicle_modules, :model_modules, model: [:manufacturer])

        scope = scope.where(loaner: loaner_included?)

        @q = scope.ransack(vehicle_query_params)

        @vehicles = @q.result(distinct: true)
          .includes(:model)
          .joins(:model)
          .sort_by { |vehicle| [-vehicle.model.length, vehicle.model.name] }
      end

      def public_fleetchart
        authorize! :read, :api_fleet

        @fleet = Fleet.find_by!(slug: params[:slug])

        unless fleet.public_fleet?
          @vehicles = Kaminari.paginate_array([]).page(params[:page]).per(per_page(Vehicle))
          return
        end

        scope = fleet.vehicles.includes(:model_paint, :vehicle_upgrades, :model_upgrades, :vehicle_modules, :model_modules, model: [:manufacturer])

        scope = scope.where(loaner: loaner_included?)

        @q = scope.ransack(vehicle_query_params)

        @vehicles = @q.result(distinct: true)
          .includes(:model)
          .joins(:model)
          .sort_by { |vehicle| [-vehicle.model.length, vehicle.model.name] }
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def quick_stats
        authorize! :show, fleet

        scope = fleet.vehicles.includes(:model, :vehicle_upgrades, :model_upgrades, :vehicle_modules, :model_modules)

        scope = scope.where(loaner: loaner_included?)

        @q = scope.ransack(vehicle_query_params)

        @q.sorts = ["model_classification asc"]

        vehicles = @q.result
        models = vehicles.map(&:model)
        upgrades = vehicles.map(&:model_upgrades).flatten
        modules = vehicles.map(&:model_modules).flatten

        @quick_stats = QuickStats.new(
          total: vehicles.count,
          classifications: models.map(&:classification).uniq.compact.map do |classification|
            ClassificationCount.new(
              classification_count: models.count { |model| model.classification == classification },

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
      # rubocop:enable Metrics/CyclomaticComplexity

      private def fleet
        @fleet ||= current_user.fleets.where(slug: params[:slug]).first!
      end

      private def price_range
        @price_range ||= price_in.map do |prices|
          gt_price, lt_price = prices.split("-")
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
          gt_price, lt_price = prices.split("-")
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
        pledge_price_in = vehicle_query_params.delete("pledge_price_in")
        pledge_price_in = pledge_price_in.to_s.split unless pledge_price_in.is_a?(Array)
        pledge_price_in
      end

      private def price_in
        price_in = vehicle_query_params.delete("price_in")
        price_in = price_in.to_s.split unless price_in.is_a?(Array)
        price_in
      end

      private def vehicle_query_params
        @vehicle_query_params ||= query_params(
          :model_name_cont, :model_name_or_model_description_cont, :on_sale_eq,
          :length_gteq, :length_lteq, :price_gteq, :price_lteq, :pledge_price_gteq,
          :pledge_price_lteq, :loaner_eq,
          model_slug_in: [], manufacturer_in: [], classification_in: [], focus_in: [],
          size_in: [], price_in: [], pledge_price_in: [],
          production_status_in: [], sorts: [], member_in: []
        )
      end

      private def model_query_params
        @model_query_params ||= query_params(
          :name_cont, :description_cont, :name_or_description_cont, :on_sale_eq, :sorts,
          :length_gteq, :length_lteq, :price_gteq, :price_lteq, :pledge_price_gteq,
          :pledge_price_lteq, :will_it_fit, :search_cont, :loaner_eq,
          name_in: [], manufacturer_in: [], classification_in: [], focus_in: [],
          production_status_in: [], price_in: [], pledge_price_in: [], size_in: [], sorts: [],
          id_not_in: [], member_in: []
        )
      end

      private def loaner_param
        @loaner_param ||= vehicle_query_params.delete("loaner_eq") || model_query_params.delete("loaner_eq")
      end

      private def loaner_included?
        return false if loaner_param.blank?

        return true if loaner_param == "only"

        [false, true]
      end
      helper_method :loaner_included?

      private def for_members
        return if vehicle_query_params[:member_in].blank?

        @for_members ||= User.where(username: vehicle_query_params[:member_in]).pluck(:id)
      end
    end
  end
end
