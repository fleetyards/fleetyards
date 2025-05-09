# frozen_string_literal: true

module Api
  module V1
    class ModelsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      after_action -> { pagination_header(:models) }, only: %i[index with_docks cargo_options]
      after_action -> { pagination_header(:variants) }, only: [:variants]
      after_action -> { pagination_header(:loaners) }, only: [:loaners]
      after_action -> { pagination_header(:images) }, only: [:images]
      after_action -> { pagination_header(:videos) }, only: [:videos]

      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t("messages.record_not_found.model", slug: params[:slug]))
      end

      def index
        authorize! :index, :api_models

        @q = index_scope

        @models = @q.result
          .page(params[:page])
          .per(per_page(Model))
      end

      def with_docks
        authorize! :index, :api_models

        params[:withDock] = true

        @q = index_scope

        @models = @q.result
          .page(params[:page])
          .per(per_page(Model))
      end

      def fleetchart
        authorize! :index, :api_models

        @q = index_scope

        @models = @q.result
          .sort_by { |model| [-model.length, model.name] }
      end

      def unscheduled
        authorize! :index, :api_models

        @models = Model.visible
          .active
          .where.not(id: RoadmapItem.pluck(:model_id).compact)
          .where.not(rsi_id: nil)
          .where.not(production_status: ["flight-ready"])
          .order(name: :asc)
          .all
      end

      def slugs
        authorize! :index, :api_models

        render json: Model.order(slug: :asc).all.pluck(:slug)
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

        model_query_params["sorts"] = sorting_params(Model)

        @q = Model.visible
          .active
          .where("cargo > 0")
          .ransack(model_query_params)

        @models = @q.result
          .page(params[:page])
          .per(per_page(Model))
      end

      def latest
        authorize! :index, :api_models

        @models = Model.visible.includes(:manufacturer)
          .active
          .order(last_updated_at: :desc, name: :asc)
          .limit(9)
      end

      def embed
        authorize! :index, :api_models

        @models = Model.visible.active.where(slug: params[:models]).order(name: :asc).all

        render "api/v1/models/index"
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

      def hardpoints
        authorize! :show, :api_models

        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!

        scope = model.model_hardpoints.includes(:component).undeleted

        scope = scope.where(source: params[:source]) if params[:source].present?

        @hardpoints = scope
      end

      def images
        authorize! :show, :api_models

        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!

        @images = model.images
          .enabled
          .order("images.created_at desc")
          .page(params[:page])
          .per(per_page(Image))
      end

      def videos
        authorize! :show, :api_models

        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!

        @videos = model.videos
          .order("videos.created_at desc")
          .page(params[:page])
          .per(per_page(Video))
      end

      def variants
        authorize! :show, :api_models

        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!

        scope = model.variants.includes(:manufacturer).visible.active
        if pledge_price_range.present?
          model_query_params["sorts"] = "pledge_price asc"
          scope = scope.where(pledge_price: pledge_price_range)
        end
        if price_range.present?
          model_query_params["sorts"] = "price asc"
          scope = scope.where(price: price_range)
        end

        model_query_params["sorts"] = sorting_params(Model)

        @q = scope.ransack(model_query_params)

        @variants = @q.result
          .page(params[:page])
          .per(per_page(Model))
      end

      def loaners
        authorize! :show, :api_models

        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!

        scope = model.loaners.includes(:manufacturer).visible.active

        if pledge_price_range.present?
          model_query_params["sorts"] = "pledge_price asc"
          scope = scope.where(pledge_price: pledge_price_range)
        end

        if price_range.present?
          model_query_params["sorts"] = "price asc"
          scope = scope.where(price: price_range)
        end

        model_query_params["sorts"] = sorting_params(Model)

        @q = scope.ransack(model_query_params)

        @loaners = @q.result
          .page(params[:page])
          .per(per_page(Model))
      end

      def modules
        authorize! :show, :api_models

        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!

        @model_modules = model.modules
          .visible
          .active
          .order(name: :asc)
          .page(params[:page])
          .per(per_page(ModelModule))
      end

      def module_packages
        authorize! :show, :api_models

        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!

        @module_packages = model.module_packages
          .visible
          .active
          .order(name: :asc)
          .page(params[:page])
          .per(per_page(ModelModule))
      end

      def upgrades
        authorize! :show, :api_models

        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!

        @model_upgrades = model.upgrades
          .visible
          .active
          .order(name: :asc)
      end

      def paints
        authorize! :show, :api_models

        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!

        @paints = model.paints
          .visible
          .active
          .order(name: :asc)
      end

      def store_image
        authorize! :show, :api_models

        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first
        model = ModelUpgrade.visible.active.where(slug: params[:slug]).first if model.blank?
        model = Model.new if model.blank?

        redirect_to model.store_image.url, allow_other_host: true
      end

      def fleetchart_image
        authorize! :show, :api_models

        model = Model
          .visible
          .active
          .where(slug: params[:slug])
          .or(Model.where(rsi_slug: params[:slug]))
          .where.not(fleetchart_image: nil)
          .first!

        redirect_to model.fleetchart_image.url, allow_other_host: true
      end

      def snub_crafts
        authorize! :show, :api_models

        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!

        @snub_crafts = model.snub_crafts
          .visible
          .active
          .order(name: :asc)
      end

      private def price_range
        @price_range ||= price_in.map do |prices|
          gt_price, lt_price = prices.split("-")
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

      private def pledge_price_range
        @pledge_price_range ||= pledge_price_in.map do |prices|
          gt_price, lt_price = prices.split("-")
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

      private def index_scope
        scope = Model.includes([:manufacturer]).visible.active

        if pledge_price_range.present?
          model_query_params["sorts"] = "pledge_price asc"
          scope = scope.where(pledge_price: pledge_price_range)
        end

        if price_range.present?
          model_query_params["sorts"] = "price asc"
          scope = scope.where(price: price_range)
        end

        scope = scope.with_dock if params[:withDock]
        scope = will_it_fit?(scope) if model_query_params["will_it_fit"].present?

        model_query_params["sorts"] = sorting_params(Model)

        scope.ransack(model_query_params)
      end

      private def will_it_fit?(scope)
        slug = model_query_params.delete("will_it_fit")
        parent = Model.visible.active.where(slug:).or(Model.where(rsi_slug: slug)).first

        return scope if parent.blank? || parent.docks.blank?

        query = []
        parent.docks.each do |dock|
          query << "length <= #{dock.length - 0.5} and beam <= #{dock.beam - 0.5} and height <= #{dock.height - 0.5}"
          query << "or" unless dock == parent.docks.last
        end

        scope = scope.where(query.join(" ")) if query.present?

        scope
      end

      private def pledge_price_in
        pledge_price_in = model_query_params.delete("pledge_price_in")
        pledge_price_in = pledge_price_in.to_s.split unless pledge_price_in.is_a?(Array)
        pledge_price_in
      end

      private def price_in
        price_in = model_query_params.delete("price_in")
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
          :length_gteq, :length_lteq, :beam_gteq, :beam_lteq, :height_gteq, :height_lteq,
          :price_gteq, :price_lteq, :pledge_price_gteq, :pledge_price_lteq, :will_it_fit,
          :search_cont,
          name_in: [], manufacturer_in: [], classification_in: [], focus_in: [],
          production_status_in: [], price_in: [], pledge_price_in: [], size_in: [], sorts: [],
          id_not_in: [], id_in: []
        )
      end
    end
  end
end
