# frozen_string_literal: true

module Api
  module V1
    class ModelsController < ::Api::V1::BaseController
      before_action :authenticate_api_user!, only: []
      after_action -> { pagination_header(:models) }, only: [:index]
      after_action -> { pagination_header(:images) }, only: [:images]
      after_action -> { pagination_header(:videos) }, only: [:videos]

      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t('messages.record_not_found.model', slug: params[:slug]))
      end

      def index
        authorize! :index, :api_models

        @q = index_scope

        @models = @q.result
                    .page(params[:page])
                    .per(per_page(Model))
      end

      def fleetchart
        authorize! :index, :api_models

        @q = index_scope

        @models = @q.result
                    .sort_by { |model| [-model.display_length, model.name] }
      end

      def slugs
        authorize! :index, :api_models
        render json: Model.all.pluck(:slug)
      end

      def production_states
        authorize! :index, :api_models
        @production_states = Model.production_status_filters
      end

      def classifications
        authorize! :index, :api_models
        @classifications = Model.classification_filters
      end

      def focus
        authorize! :index, :api_models
        @focus = Model.focus_filters
      end

      def sizes
        authorize! :index, :api_models
        @sizes = Model.size_filters
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

        @models = Model.visible
                       .active
                       .where('cargo > 0')
                       .order(name: :asc)
                       .all
      end

      def latest
        authorize! :index, :api_models
        @models = Model.visible
                       .active
                       .order(last_updated_at: :desc, name: :asc)
                       .limit(9)
      end

      def embed
        authorize! :index, :api_models

        @models = Model.visible.active.where(slug: params[:models]).order(name: :asc)

        render 'api/v1/models/index'
      end

      def updated
        authorize! :index, :api_models
        if updated_range.present?
          scope = Model.visible.active.where(updated_at: updated_range)
          @models = scope.order(updated_at: :desc, name: :asc)
        else
          render json: [], status: :not_modified
        end
      end

      def show
        authorize! :show, :api_models
        @model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!
      end

      def images
        authorize! :show, :api_models
        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!
        @images = model.images
                       .enabled
                       .order('images.created_at desc')
                       .page(params[:page])
                       .per(per_page(Image))
      end

      def videos
        authorize! :show, :api_models
        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!
        @videos = model.videos
                       .order('videos.created_at desc')
                       .page(params[:page])
                       .per(per_page(Video))
      end

      def variants
        authorize! :show, :api_models
        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!

        scope = model.variants.visible.active
        if pledge_price_range.present?
          model_query_params['sorts'] = 'fallback_pledge_price asc'
          scope = scope.where(fallback_pledge_price: pledge_price_range)
        end
        if price_range.present?
          model_query_params['sorts'] = 'price asc'
          scope = scope.where(price: price_range)
        end

        model_query_params['sorts'] = sort_by_name

        @q = scope.ransack(model_query_params)

        @variants = @q.result
                      .page(params[:page])
                      .per(per_page(Model))
      end

      def modules
        authorize! :show, :api_models
        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!

        @model_modules = model.modules
                              .visible
                              .active
                              .page(params[:page])
                              .per(per_page(ModelModule))
      end

      def upgrades
        authorize! :show, :api_models
        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!

        @model_upgrades = model.upgrades
                               .visible
                               .active
                               .page(params[:page])
                               .per(per_page(ModelUpgrade))
      end

      def store_image
        authorize! :show, :api_models
        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first || Model.new
        redirect_to model.store_image.url
      end

      def fleetchart_image
        authorize! :show, :api_models
        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!
        redirect_to model.fleetchart_image.url
      end

      private def price_range
        @price_range ||= begin
          price_in.map do |prices|
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

      private def pledge_price_range
        @pledge_price_range ||= begin
          pledge_price_in.map do |prices|
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

      private def index_scope
        scope = Model.visible.active
        if pledge_price_range.present?
          model_query_params['sorts'] = 'fallback_pledge_price asc'
          scope = scope.where(fallback_pledge_price: pledge_price_range)
        end
        if price_range.present?
          model_query_params['sorts'] = 'price asc'
          scope = scope.where(price: price_range)
        end

        model_query_params['sorts'] = sort_by_name

        scope.ransack(model_query_params)
      end

      private def pledge_price_in
        pledge_price_in = model_query_params.delete('pledge_price_in')
        pledge_price_in = pledge_price_in.to_s.split unless pledge_price_in.is_a?(Array)
        pledge_price_in
      end

      private def price_in
        price_in = model_query_params.delete('price_in')
        price_in = price_in.to_s.split unless price_in.is_a?(Array)
        price_in
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

      private def model_query_params
        @model_query_params ||= query_params(
          :name_cont, :description_cont, :name_or_description_cont, :on_sale_eq, :sorts,
          manufacturer_in: [], classification_in: [], focus_in: [], production_status_in: [],
          price_in: [], pledge_price_in: [], size_in: [], sorts: []
        )
      end
    end
  end
end
