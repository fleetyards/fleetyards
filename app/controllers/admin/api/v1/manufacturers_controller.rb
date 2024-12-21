# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ManufacturersController < ::Admin::Api::BaseController
        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.manufacturer", slug: params[:slug]))
        end

        def index
          authorize! :read, Manufacturer

          scope = Manufacturer.with_name

          scope = scope.with_model if manufacturer_query_params.delete(:with_models)

          manufacturer_query_params["sorts"] ||= sorting_params(Manufacturer)

          q = scope.ransack(manufacturer_query_params)

          @manufacturers = q.result(distinct: true)
            .page(params[:page])
            .per(per_page(Manufacturer))
        end

        private def manufacturer_query_params
          @manufacturer_query_params ||= query_params(
            :with_models, :name_eq, :name_cont, :slug_eq, :slug_cont, :logo_blank,
            name_in: [], slug_in: []
          )
        end
      end
    end
  end
end
