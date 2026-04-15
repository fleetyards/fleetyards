# frozen_string_literal: true

module Api
  module V1
    module Public
      class HangarStatsController < ::Api::PublicBaseController
        include HangarFiltersConcern
        include ChartHelper

        before_action :set_user

        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity
        def show
          scope = @user.vehicles
            .includes(:vehicle_upgrades, :model_upgrades, :vehicle_modules, :model_modules, :model)
            .purchased
            .public
            .where(loaner: false)

          scope = will_it_fit?(scope) if vehicle_query_params["will_it_fit"].present?

          @q = scope.ransack(vehicle_query_params)

          @q.sorts = ["model_classification asc"]

          vehicles = @q.result

          ingame_vehicles = vehicles.select(&:bought_via_ingame?)
          pledge_store_vehicles = vehicles.select(&:bought_via_pledge_store?)
          models = vehicles.map(&:model)
          non_loaner_models = vehicles.reject(&:loaner?).map(&:model)
          pledge_store_models = pledge_store_vehicles.filter_map do |vehicle|
            vehicle.model unless vehicle.loaner?
          end
          ingame_models = ingame_vehicles.map(&:model)
          upgrades = vehicles.map(&:model_upgrades).flatten
          modules = vehicles.map(&:model_modules).flatten

          wishlist_models = if @user.public_wishlist?
            @user.vehicles.wanted.public.where(loaner: false).includes(:model).map(&:model)
          else
            []
          end

          @quick_stats = QuickStats.new(
            total: vehicles.count,
            wishlist_total: @user.public_wishlist ? @user.vehicles.wanted.public.where(loaner: false).count : nil,
            classifications: Model.classifications.map do |classification|
              ClassificationCount.new(
                classification_count: models.count { |model| model.classification == classification },

                name: classification,
                label: classification.humanize
              )
            end,
            groups: HangarGroup.where(user: @user, public: true).order([{sort: :asc, name: :asc}]).map do |group|
              HangarGroupCount.new(
                group_count: group.vehicles.where(id: vehicles.map(&:id)).size,
                id: group.id,
                slug: group.slug
              )
            end,
            metrics: hangar_metrics(models, non_loaner_models, pledge_store_models, ingame_models, modules, upgrades, wishlist_models)
          )
        end
        # rubocop:enable Metrics/PerceivedComplexity
        # rubocop:enable Metrics/CyclomaticComplexity

        def models_by_size
          models_by_size = transform_for_pie_chart(
            @user.vehicles.purchased.public.where(loaner: false)
                 .joins(:model)
                 .group("models.size").count
                 .map { |label, count| {(label.present? ? label.humanize : I18n.t("labels.unknown")) => count} }
                 .reduce(:merge) || []
          )

          render json: models_by_size.to_json
        end

        def models_by_production_status
          models_by_production_status = transform_for_pie_chart(
            @user.vehicles.purchased.public.where(loaner: false)
                 .joins(:model)
                 .group("models.production_status").count
                 .map { |label, count| {(label.present? ? label.humanize : I18n.t("labels.unknown")) => count} }
                 .reduce(:merge) || []
          )

          render json: models_by_production_status.to_json
        end

        def models_by_manufacturer
          models_by_manufacturer = transform_for_pie_chart(
            @user.manufacturers.uniq
                .map do |manufacturer|
                  model_ids = manufacturer.model_ids
                  {manufacturer.name => @user.vehicles.purchased.public.where(loaner: false, model_id: model_ids).count}
                end
                .reduce(:merge) || []
          )

          render json: models_by_manufacturer.to_json
        end

        def models_by_classification
          models_by_classification = transform_for_pie_chart(
            @user.vehicles.purchased.public.where(loaner: false)
                 .joins(:model)
                 .group("models.classification").count
                 .map { |label, count| {(label.present? ? label.humanize : I18n.t("labels.unknown")) => count} }
                 .reduce(:merge) || []
          )

          render json: models_by_classification.to_json
        end

        private

        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity
        def hangar_metrics(models, non_loaner_models, pledge_store_models, ingame_models, modules, upgrades, wishlist_models)
          lengths = models.filter_map { |m| m.length if m.length&.positive? }
          unique_model_ids = non_loaner_models.each_with_object(Set.new) { |m, set| set.add(m.id) }
          manufacturer_ids = non_loaner_models.each_with_object(Set.new) { |m, set| set.add(m.manufacturer_id) if m.manufacturer_id }
          present_classifications = non_loaner_models.each_with_object(Set.new) { |m, set| set.add(m.classification) if m.classification }
          missing_classifications = Model.classifications - present_classifications.to_a

          {
            total_money: pledge_store_models.map(&:pledge_price).sum(&:to_i) + modules.map(&:pledge_price).sum(&:to_i) + upgrades.map(&:pledge_price).sum(&:to_i),
            total_credits: ingame_models.map(&:price).sum(&:to_i),
            total_ingame_value: non_loaner_models.map(&:price).sum(&:to_i),
            total_min_crew: models.map(&:min_crew).sum(&:to_i),
            total_max_crew: models.map(&:max_crew).sum(&:to_i),
            total_cargo: models.map(&:cargo).sum(&:to_i),
            largest_ship: lengths.max,
            smallest_ship: lengths.min,
            average_pledge_price: pledge_store_models.any? ? (pledge_store_models.map(&:pledge_price).sum(&:to_i) / pledge_store_models.size) : 0,
            flight_ready_count: non_loaner_models.count { |m| m.production_status == "flight-ready" },
            unique_models_count: unique_model_ids.size,
            manufacturer_count: manufacturer_ids.size,
            missing_classifications: missing_classifications,
            wishlist_total_money: wishlist_models.map(&:pledge_price).sum(&:to_i),
            wishlist_total_credits: wishlist_models.map(&:price).sum(&:to_i)
          }
        end
        # rubocop:enable Metrics/PerceivedComplexity
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/MethodLength

        def set_user
          @user = User.find_by!(normalized_username: params[:hangar_username].downcase)

          authorize! @user, to: :show_stats?, with: ::Public::UserPolicy
        end
      end
    end
  end
end
