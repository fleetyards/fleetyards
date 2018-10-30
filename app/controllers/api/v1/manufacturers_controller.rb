# frozen_string_literal: true

module Api
  module V1
    class ManufacturersController < ::Api::V1::BaseController
      before_action :authenticate_api_user!, only: []
      after_action -> { pagination_header(:manufacturers) }, only: [:index]

      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t('messages.record_not_found.manufacturer', slug: params[:slug]))
      end

      def index
        authorize! :index, :api_manufacturers
        scope = Manufacturer.with_name

        scope = scope.with_model if params[:with_model]

        manufacturer_query_params['sorts'] = sort_by_name

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
    end
  end
end
