# frozen_string_literal: true

module Api
  module V2
    module Hangar
      module Public
        class StatsController < ::Api::V2::BaseController
          before_action :authenticate_user!, only: []

          def show
            user = User.find_by!("lower(username) = ?", params.fetch(:username, "").downcase)

            unless user.public_hangar?
              not_found
              return
            end

            scope = user.vehicles
              .includes(:vehicle_upgrades, :model_upgrades, :vehicle_modules, :model_modules, :model)
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

          private def vehicle_query_params
            @vehicle_query_params ||= query_params(
              :name_cont, :model_name_or_model_description_cont, :on_sale_eq, :length_gteq, :length_lteq,
              manufacturer_in: [], classification_in: [], focus_in: [],
              size_in: [], production_status_in: [], hangar_groups_in: [], hangar_groups_not_in: []
            )
          end
        end
      end
    end
  end
end
