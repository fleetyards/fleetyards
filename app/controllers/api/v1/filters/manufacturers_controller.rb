# frozen_string_literal: true

module Api
  module V1
    module Filters
      class ManufacturersController < ::Api::PublicBaseController
        skip_verify_authorized

        def options
          manufacturer_query_params["sorts"] = "name asc"

          @q = Manufacturer.with_name.with_model.ransack(manufacturer_query_params)

          @manufacturers = result_with_pagination(@q.result(distinct: true), per_page(Manufacturer))
        end

        private def manufacturer_query_params
          @manufacturer_query_params ||= params.permit(
            q: [
              :name_cont, :name_eq, :slug_eq, :slug_cont,
              name_in: [], slug_in: []
            ]
          )[:q].presence || {}
        end
      end
    end
  end
end
