# frozen_string_literal: true

module Api
  module V1
    class ModelsController < ::Api::V1::BaseController
      before_action :authenticate_api_user!, only: []
      after_action -> { pagination_header(:models) }, only: [:index]

      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t('messages.record_not_found.model', slug: params[:slug]))
      end

      def index
        authorize! :index, :api_models
        scope = Model.visible
        if price_range.present?
          query_params['sorts'] = 'fallback_price asc'
          scope = scope.where(fallback_price: price_range)
        end

        @q = scope.ransack(query_params)

        @q.sorts = 'name asc' if @q.sorts.empty?

        @models = @q.result
                    .page(params[:page])
                    .per([(params[:per_page] || Model.default_per_page), Model.default_per_page * 4].min)
      end

      def filters
        authorize! :index, :api_models
        @filters ||= begin
          filters = []
          filters << Manufacturer.model_filters
          filters << Model.production_status_filters
          filters << Model.classification_filters
          filters << Model.focus_filters
          filters << Model.size_filters
          filters.flatten
                 .sort_by { |filter| [filter.category, filter.name] }
        end
      end

      def cargo_options
        authorize! :index, :api_models

        @models = Model.where('cargo > 0')
                       .order(name: :asc)
                       .all
      end

      def latest
        authorize! :index, :api_models
        @models = Model.order(last_updated_at: :desc, name: :asc)
                       .limit(8)
      end

      def embed
        authorize! :index, :api_models

        @models = Model.where(slug: params[:models]).order(name: :asc)

        render 'api/v1/models/index'
      end

      def updated
        authorize! :index, :api_models
        if updated_range.present?
          scope = Model.where(updated_at: updated_range)
          @models = scope.order(updated_at: :desc, name: :asc)
        else
          render json: [], status: :not_modified
        end
      end

      def show
        authorize! :show, :api_models
        @model = Model.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!
      end

      def store_image
        authorize! :show, :api_models
        model = Model.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first || Model.new
        redirect_to model.store_image.url
      end

      def fleetchart_image
        authorize! :show, :api_models
        model = Model.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!
        redirect_to model.fleetchart_image.url
      end

      private def price_range
        @price_range ||= begin
          (query_params.delete('price_in') || []).map do |prices|
            gt_price, lt_price = prices.split('-')
            gt_price = if gt_price.blank?
                         0
                       else
                         gt_price.to_i
                       end
            lt_price = if lt_price.blank?
                         Float::INFINITY
                       else
                         lt_price.to_i
                       end
            (gt_price...lt_price)
          end
        end
      end

      private def updated_range
        return if updated_params[:from].blank?
        to = updated_params[:to] || Time.zone.now
        [updated_params[:from]...to]
      end

      private def updated_params
        @updated_params ||= params.permit(
          :from, :to
        )
      end
    end
  end
end
