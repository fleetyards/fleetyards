# frozen_string_literal: true

module Api
  module V1
    module Filters
      class ModelsController < ::Api::PublicBaseController
        include ModelCargoFiltersConcern

        skip_verify_authorized

        def production_states
          @filters = Model.production_status_filters

          render "api/v1/shared/filters"
        end

        def classifications
          @filters = Model.classification_filters

          render "api/v1/shared/filters"
        end

        def focus
          @filters = Model.focus_filters(classification: params[:classification].presence)

          render "api/v1/shared/filters"
        end

        def sizes
          @filters = Model.size_filters

          render "api/v1/shared/filters"
        end

        def dock_sizes
          @filters = Model.dock_size_filters

          render "api/v1/shared/filters"
        end

        def index
          @filters ||= begin
            filters = []
            filters << Manufacturer.model_filters
            filters << Model.production_status_filters
            filters << Model.classification_filters
            filters << Model.focus_filters
            filters << Model.size_filters
            filters.flatten
              .sort_by { |filter| [filter.category, filter.label] }
          end

          render "api/v1/shared/filters"
        end

        def options
          normalize_sort_params(model_query_params)
          model_query_params["sorts"] = sorting_params(Model, model_query_params["sorts"])

          scope = Model.visible.active.includes(:manufacturer)
          scope = with_cargo_grids(scope) if model_query_params.delete("with_cargo_grids")
          scope = scope.where(id: current_resource_owner.models.select(:id)) if model_query_params.delete("in_hangar") && current_resource_owner.present?
          scope = container_fit(scope) if container_fit_params.present?

          @q = scope.ransack(model_query_params)

          @models = result_with_pagination(@q.result, per_page(Model))

          @owned_model_ids, @wanted_model_ids = hangar_model_ids(@models)
        end

        # Which of the models on this page the current user already has a vehicle
        # for, split by wanted, so the option rows can be marked without asking
        # per row - Model#in_hangar is one query each.
        private def hangar_model_ids(models)
          return [[], []] if current_resource_owner.blank?

          pairs = current_resource_owner.vehicles
            .where(model_id: models.map(&:id))
            .pluck(:model_id, :wanted)

          [
            pairs.reject(&:second).map(&:first).uniq,
            pairs.select(&:second).map(&:first).uniq
          ]
        end

        private def model_query_params
          @model_query_params ||= params.permit(
            q: [
              :name_cont, :name_eq, :slug_eq, :search_cont, :in_hangar, :with_cargo_grids, :s, :sorts,
              name_in: [], slug_in: [], id_in: [], id_not_in: [],
              manufacturer_in: [], classification_in: [], focus_in: [],
              size_in: [], production_status_in: []
            ]
          )[:q].presence || {}
        end
      end
    end
  end
end
