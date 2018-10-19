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

        query_params['sorts'] = sort_by_name

        @q = scope.ransack(query_params)

        @manufacturers = @q.result
                           .page(params[:page])
                           .per(per_page(Manufacturer))
      end
    end
  end
end
