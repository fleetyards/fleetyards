# frozen_string_literal: true

module Api
  module V1
    class ModelsController < ::Api::BaseController
      include ViteRails::TagHelpers

      skip_verify_authorized

      before_action :authenticate_user!, only: []
      after_action -> { pagination_header(:images) }, only: [:images]
      after_action -> { pagination_header(:videos) }, only: [:videos]

      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t("messages.record_not_found.model", slug: params[:slug]))
      end

      def index
        @q = index_scope

        @models = @q.result
          .page(params[:page])
          .per(per_page(Model))
      end

      def with_docks
        model_query_params[:with_dock] = true

        @q = index_scope

        @models = @q.result
          .page(params[:page])
          .per(per_page(Model))

        render "api/v1/models/index"
      end

      def fleetchart
        @q = index_scope

        @models = @q.result
          .sort_by { |model| [-model.length, model.name] }
      end

      def slugs
        render json: Model.order(slug: :asc).all.pluck(:slug)
      end

      def production_states
        @production_states = Model.production_status_filters
      end

      def classifications
        @classifications = Model.classification_filters
      end

      def focus
        @focus = Model.focus_filters
      end

      def sizes
        @sizes = Model.size_filters
      end

      def dock_sizes
        @dock_sizes = Model.dock_size_filters
      end

      def filters
        @filters ||= begin
          filters = []
          filters << Manufacturer.model_filters
          filters << Model.production_status_filters
          filters << Model.classification_filters
          filters << Model.focus_filters
          filters << Model.size_filters
          filters.flatten
            .sort_by { |filter| [filter.category, filter.label] }
        end
      end

      def cargo_options
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
        @models = Model.visible.includes(:manufacturer)
          .active
          .order(last_updated_at: :desc, name: :asc)
          .limit(9)
      end

      def embed
        @models = Model.visible.active.where(slug: params[:models]).order(name: :asc).all
      end

      def updated
        if updated_range.present?
          scope = Model.visible.active.where(updated_at: updated_range)
          @models = scope.order(updated_at: :desc, name: :asc)
        else
          render json: [], status: :not_modified
        end
      end

      def show
        @model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!
      end

      def hardpoints
        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!

        scope = if feature_enabled?("hardpoints-v2")
          model.hardpoints.includes(:component)
        else
          model.model_hardpoints.includes(:component).undeleted
        end

        scope = scope.where(source: params[:source]) if params[:source].present?

        @hardpoints = scope

        if feature_enabled?("hardpoints-v2")
          render "api/v1/models/hardpoints"
        else
          render "api/v1/models/hardpoints_old"
        end
      end

      def images
        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!

        @images = model.images
          .enabled
          .order("images.created_at desc")
          .page(params[:page])
          .per(per_page(Image))
      end

      def videos
        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!

        @videos = model.videos
          .order("videos.created_at desc")
          .page(params[:page])
          .per(per_page(Video))
      end

      def variants
        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!

        scope = model.variants.includes(:manufacturer).visible.active
        if pledge_price_range.present?
          model_query_params["sorts"] = "last_pledge_price asc"
          scope = scope.where(last_pledge_price: pledge_price_range)
        end
        if price_range.present?
          model_query_params["sorts"] = "price asc"
          scope = scope.where(price: price_range)
        end

        model_query_params["sorts"] = sorting_params(Model)

        @q = scope.ransack(model_query_params)

        @models = @q.result
          .page(params[:page])
          .per(per_page(Model))

        render "api/v1/models/index"
      end

      def loaners
        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!

        scope = model.loaners.includes(:manufacturer).visible.active

        if pledge_price_range.present?
          model_query_params["sorts"] = "last_pledge_price asc"
          scope = scope.where(last_pledge_price: pledge_price_range)
        end

        if price_range.present?
          model_query_params["sorts"] = "price asc"
          scope = scope.where(price: price_range)
        end

        model_query_params["sorts"] = sorting_params(Model)

        @q = scope.ransack(model_query_params)

        @models = @q.result
          .page(params[:page])
          .per(per_page(Model))

        render "api/v1/models/index"
      end

      def modules
        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!

        @model_modules = model.modules
          .visible
          .active
          .order(name: :asc)
          .page(params[:page])
          .per(per_page(ModelModule))
      end

      def module_packages
        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!

        @module_packages = model.module_packages
          .visible
          .active
          .order(name: :asc)
          .page(params[:page])
          .per(per_page(ModelModule))
      end

      def upgrades
        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!

        @model_upgrades = model.upgrades
          .visible
          .active
          .order(name: :asc)
      end

      def paints
        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first!

        @paints = model.paints
          .visible
          .active
          .order(name: :asc)
      end

      def store_image
        model = Model.visible.active.where(slug: params[:slug]).or(Model.where(rsi_slug: params[:slug])).first
        model = ModelUpgrade.visible.active.where(slug: params[:slug]).first if model.blank?
        model = Model.new if model.blank?

        store_image_url = model.store_image.url
        store_image_url = vite_asset_url("images/fallback/store_image.jpg") if store_image_url.blank?

        redirect_to store_image_url, allow_other_host: true
      end

      def fleetchart_image
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
          model_query_params["sorts"] = "last_pledge_price asc"
          scope = scope.where(last_pledge_price: pledge_price_range)
        end

        if price_range.present?
          model_query_params["sorts"] = "price asc"
          scope = scope.where(price: price_range)
        end

        scope = scope.with_dock if model_query_params.delete("with_dock")
        scope = scope.where(cargo: 0.1..) if model_query_params.delete("with_cargo")
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
          :name_cont, :name_eq, :slug_eq, :description_cont, :name_or_description_cont, :on_sale_eq,
          :sorts, :length_gteq, :length_lteq, :beam_gteq, :beam_lteq, :height_gteq, :height_lteq,
          :price_gteq, :price_lteq, :pledge_price_gteq, :pledge_price_lteq, :search_cont,
          :with_dock, :with_cargo,
          will_it_fit: [], name_in: [], slug_in: [], manufacturer_in: [], classification_in: [],
          focus_in: [], production_status_in: [], price_in: [], pledge_price_in: [], size_in: [],
          sorts: [], id_not_in: [], id_in: []
        )
      end
    end
  end
end
