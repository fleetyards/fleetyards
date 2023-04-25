# frozen_string_literal: true

module Api
  module V1
    module Public
      class HangarStatsController < ::Api::PublicBaseController
        include HangarFiltersConcern

        def show
          user = User.find_by!("lower(username) = ?", params.fetch(:hangar_username, "").downcase)

          unless user.public_hangar?
            not_found
            return
          end

          scope = user.vehicles
            .includes(:vehicle_upgrades, :model_upgrades, :vehicle_modules, :model_modules, :model)
            .purchased
            .public
            .where(loaner: false)

          @q = scope.ransack(vehicle_query_params)

          @q.sorts = ["model_classification asc"]

          vehicles = @q.result

          models = vehicles.map(&:model)

          @quick_stats = QuickStats.new(
            total: vehicles.count,
            classifications: Model.classifications.map do |classification|
              ClassificationCount.new(
                classification_count: models.count { |model| model.classification == classification },

                name: classification,
                label: classification.humanize
              )
            end,
            groups: HangarGroup.where(user:, public: true).order([{ sort: :asc, name: :asc }]).map do |group|
              HangarGroupCount.new(
                group_count: group.vehicles.where(id: vehicles.map(&:id)).size,
                id: group.id,
                slug: group.slug
              )
            end
          )
        end
      end
    end
  end
end
