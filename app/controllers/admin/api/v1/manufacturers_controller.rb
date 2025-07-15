# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ManufacturersController < ::Admin::Api::BaseController
        before_action :set_manufacturer, only: %i[show]

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.manufacturer", slug: params[:slug]))
        end

        def index
          authorize! with: ::Admin::ManufacturerPolicy

          scope = Manufacturer.with_name

          scope = scope.with_model if manufacturer_query_params.delete(:with_models)

          manufacturer_query_params["sorts"] = sorting_params(Manufacturer, manufacturer_query_params[:sorts])

          q = scope.ransack(manufacturer_query_params)

          @manufacturers = q.result(distinct: true)
            .page(params[:page])
            .per(per_page(Manufacturer))
        end

        def show
        end

        private def set_manufacturer
          @manufacturer = Manufacturer.find(params[:id])

          authorize! @manufacturer, with: ::Admin::ManufacturerPolicy
        end

        private def manufacturer_query_params
          @manufacturer_query_params ||= params.permit(q: [
            :with_models, :name_eq, :name_cont, :slug_eq, :slug_cont, :logo_blank, :sorts,
            name_in: [], slug_in: [], sorts: []
          ]).fetch(:q, {})
        end
      end
    end
  end
end
