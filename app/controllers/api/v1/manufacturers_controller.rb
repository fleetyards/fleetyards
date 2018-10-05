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

        Rails.logger.debug(query_params.to_yaml)
        @q = scope.ransack(query_params)

        @q.sorts = 'name asc' if @q.sorts.empty?

        @manufacturers = @q.result
                           .page(params[:page])
                           .per(per_page(Manufacturer))
      end
    end
  end
end
