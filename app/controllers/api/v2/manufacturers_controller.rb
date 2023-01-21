# frozen_string_literal: true

module Api
  module V2
    class ManufacturersController < ::Api::V2::BaseController
      before_action :authenticate_user!, only: []

      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t("messages.record_not_found.manufacturer", slug: params[:slug]))
      end

      def index
        authorize! :index, :api_manufacturers

        scope = Manufacturer.with_name

        scope = scope.with_model if with_model?

        manufacturer_query_params["sorts"] = sort_by_name

        @q = scope.ransack(manufacturer_query_params)

        @manufacturers = @q.result(distinct: true)
          .page(params[:page])
          .per(per_page(Manufacturer))
      end

      private def manufacturer_query_params
        @manufacturer_query_params ||= query_params(
          :name_cont, name_in: []
        )
      end

      private def with_model?
        params[:with_model].present? || params[:withModel].present?
      end
    end
  end
end
