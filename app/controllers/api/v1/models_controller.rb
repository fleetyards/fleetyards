# encoding: utf-8
# frozen_string_literal: true

module Api
  module V1
    class ModelsController < ::Api::V1::BaseController
      before_action :authenticate_api_user!, only: []

      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t('messages.record_not_found.model', slug: params[:slug]))
      end

      def index
        authorize! :index, :api_models
        @q = Model.enabled
                  .ransack(query_params)

        @q.sorts = 'name asc' if @q.sorts.empty?

        @models = @q.result.offset(params[:offset]).limit(params[:limit])
      end

      def filters
        authorize! :index, :api_models
        @filters ||= begin
          filters = []
          filters << Manufacturer.model_filters
          filters << Model.production_status_filters
          filters << Model.classification_filters
          filters.flatten
                 .sort_by { |filter| [filter.category, filter.name] }
        end
      end

      def latest
        authorize! :index, :api_models
        @models = Model.enabled
                       .order(updated_at: :desc, name: :asc)
                       .limit(20)
      end

      def updated
        authorize! :index, :api_models
        if updated_range.present?
          scope = Model.enabled
          scope = scope.where(updated_at: updated_range)
          @models = scope.order(updated_at: :desc, name: :asc)
        else
          render json: [], status: :not_modified
        end
      end

      def show
        authorize! :show, :api_models
        @model = Model.enabled
                      .find_by!(slug: params[:slug])
      end

      def gallery
        authorize! :index, :api_models
        model = Model.find_by!(slug: params[:slug])
        @images = model.images
                       .enabled
                       .order(created_at: :asc)
                       .page(params[:page])
                       .per(per_page)
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
