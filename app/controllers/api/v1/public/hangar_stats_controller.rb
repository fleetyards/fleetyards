# frozen_string_literal: true

module Api
  module V1
    module Public
      class HangarStatsController < ::Api::PublicBaseController
        include HangarFiltersConcern

        before_action :set_user

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

          models = vehicles.map(&:model)

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
            end
          )
        end

        private def set_user
          @user = User.find_by!(normalized_username: params[:hangar_username].downcase)

          authorize! @user, with: ::Public::UserPolicy
        end
      end
    end
  end
end
