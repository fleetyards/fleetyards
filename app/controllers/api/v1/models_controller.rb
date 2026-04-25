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
        normalize_sort_params(model_query_params)
        model_query_params["sorts"] = sorting_params(Model, model_query_params["sorts"])

        @q = Model.visible
          .active
          .where("cargo > 0")
          .ransack(model_query_params)

        @models = @q.result
          .page(params[:page])
          .per(per_page(Model))
      end

      def latest
        @models = Model.visible.includes(:manufacturer, :item_prices, model_loaners: :loaner_model)
          .active
          .order(last_updated_at: :desc, name: :asc)
          .limit(9)
      end

      def embed
        @models = Model.visible.active.includes(:manufacturer, :item_prices, model_loaners: :loaner_model)
          .where(slug: params[:models]).or(Model.where(legacy_slug: params[:models]))
          .order(name: :asc).all
      end

      def updated
        if updated_range.present?
          scope = Model.visible.active.includes(:manufacturer, :item_prices, model_loaners: :loaner_model).where(updated_at: updated_range)
          @models = scope.order(updated_at: :desc, name: :asc)
        else
          render json: [], status: :not_modified
        end
      end

      def show
        @model = find_model_by_slug!(:manufacturer, :item_prices, :docks, {model_loaners: :loaner_model})
      end

      def hardpoints
        model = find_model_by_slug!
        return if performed?

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
        model = find_model_by_slug!
        return if performed?

        @images = model.images
          .enabled
          .order("images.created_at desc")
          .page(params[:page])
          .per(per_page(Image))
      end

      def videos
        model = find_model_by_slug!
        return if performed?

        @videos = model.videos
          .order("videos.created_at desc")
          .page(params[:page])
          .per(per_page(Video))
      end

      def variants
        model = find_model_by_slug!
        return if performed?

        scope = model.variants.includes(:manufacturer, :item_prices, model_loaners: :loaner_model).visible.active
        if pledge_price_range.present?
          model_query_params["sorts"] = "pledge_price asc"
          scope = scope.where(pledge_price: pledge_price_range)
        end
        if price_range.present?
          model_query_params["sorts"] = "price asc"
          scope = scope.where(price: price_range)
        end

        normalize_sort_params(model_query_params)
        model_query_params["sorts"] = sorting_params(Model, model_query_params["sorts"])

        @q = scope.ransack(model_query_params)

        @models = @q.result
          .page(params[:page])
          .per(per_page(Model))

        render "api/v1/models/index"
      end

      def loaners
        model = find_model_by_slug!
        return if performed?

        scope = model.loaners.includes(:manufacturer, :item_prices, model_loaners: :loaner_model).visible.active

        if pledge_price_range.present?
          model_query_params["sorts"] = "pledge_price asc"
          scope = scope.where(pledge_price: pledge_price_range)
        end

        if price_range.present?
          model_query_params["sorts"] = "price asc"
          scope = scope.where(price: price_range)
        end

        normalize_sort_params(model_query_params)
        model_query_params["sorts"] = sorting_params(Model, model_query_params["sorts"])

        @q = scope.ransack(model_query_params)

        @models = @q.result
          .page(params[:page])
          .per(per_page(Model))

        render "api/v1/models/index"
      end

      def modules
        model = find_model_by_slug!
        return if performed?

        @model_modules = model.modules
          .visible
          .active
          .order(name: :asc)
          .page(params[:page])
          .per(per_page(ModelModule))

        @module_slots = model.module_hardpoints
          .where(model_module_id: @model_modules.map(&:id))
          .pluck(:model_module_id, :slot)
          .to_h
      end

      def module_packages
        model = find_model_by_slug!
        return if performed?

        @module_packages = model.module_packages
          .visible
          .active
          .order(name: :asc)
          .page(params[:page])
          .per(per_page(ModelModule))
      end

      def upgrades
        model = find_model_by_slug!
        return if performed?

        @model_upgrades = model.upgrades
          .visible
          .active
          .order(name: :asc)
      end

      def paints
        model = find_model_by_slug!
        return if performed?

        @paints = model.paints
          .visible
          .active
          .order(name: :asc)
      end

      def store_image
        model = find_model_by_slug(Model.visible.active)
        return if performed?

        model = ModelUpgrade.visible.active.where(slug: params[:slug]).first if model.blank?
        model = Model.new if model.blank?

        if model.store_image.attached?
          redirect_to rails_blob_url(model.store_image), allow_other_host: true
        else
          redirect_to vite_asset_url("images/fallback/store_image.jpg"), allow_other_host: true
        end
      end

      def fleetchart_image
        model = find_model_by_slug!(joins: :fleetchart_image_attachment)
        return if performed?

        redirect_to rails_blob_url(model.fleetchart_image), allow_other_host: true
      end

      def snub_crafts
        model = find_model_by_slug!
        return if performed?

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
        scope = Model.includes(:manufacturer, :item_prices, model_loaners: :loaner_model).visible.active

        if pledge_price_range.present?
          model_query_params["sorts"] = "pledge_price asc"
          scope = scope.where(pledge_price: pledge_price_range)
        end

        if price_range.present?
          model_query_params["sorts"] = "price asc"
          scope = scope.where(price: price_range)
        end

        scope = scope.with_dock if model_query_params.delete("with_dock")
        scope = scope.where(cargo: 0.1..) if model_query_params.delete("with_cargo")
        if model_query_params.delete("with_cargo_grids")
          scope = scope.where(
            id: Model.joins(:cargo_holds_db).select(:id)
          ).or(
            scope.where(
              id: Model.joins(:module_hardpoints).select(:id)
            )
          ).distinct
        end
        scope = scope.where(id: current_resource_owner.models.select(:id)) if model_query_params.delete("in_hangar") && current_resource_owner.present?
        scope = container_fit(scope) if container_fit_params.present?
        scope = will_it_fit?(scope) if model_query_params["will_it_fit"].present?

        normalize_sort_params(model_query_params)
        model_query_params["sorts"] = sorting_params(Model, model_query_params["sorts"])

        scope.ransack(model_query_params)
      end

      private def container_fit_params
        @container_fit_params ||= params.permit(container_fit: {})[:container_fit]
      end

      private def container_fit(scope)
        return scope if container_fit_params.blank?

        container_set = container_fit_params.to_h.transform_keys(&:to_i).transform_values(&:to_i).select { |_k, v| v > 0 }
        return scope if container_set.empty?

        scope.where(id: ScData::CargoFinderSql.find_fitting_models(container_set).select(:id))
      end

      private def find_model_by_slug!(*includes, joins: nil)
        slug = params[:slug].downcase

        scope = Model.visible.active
        scope = scope.includes(*includes) if includes.any?
        scope = scope.joins(joins) if joins
        model = scope
          .where(slug:)
          .or(Model.where(rsi_slug: slug))
          .or(Model.where(legacy_slug: slug))
          .first!

        if model.slug != slug
          redirect_to url_for(slug: model.slug), status: :moved_permanently
          return model
        end

        model
      end

      private def find_model_by_slug(scope)
        slug = params[:slug].downcase

        model = scope
          .where(slug:)
          .or(Model.where(rsi_slug: slug))
          .or(Model.where(legacy_slug: slug))
          .first

        if model.present? && model.slug != slug
          redirect_to url_for(slug: model.slug), status: :moved_permanently
          return nil
        end

        model
      end

      private def will_it_fit?(scope)
        slug = model_query_params.delete("will_it_fit")&.downcase
        parent = Model.visible.active
          .where(slug:)
          .or(Model.where(rsi_slug: slug))
          .or(Model.where(legacy_slug: slug))
          .first

        return scope if parent.blank? || parent.docks.blank?

        query = []
        parent.docks.each do |dock|
          query << "length <= #{(dock.length || 1) - 0.5} and beam <= #{(dock.beam || 1) - 0.5} and height <= #{(dock.height || 1) - 0.5}"
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
        @model_query_params ||= params.permit(
          q: [
            :name_cont, :name_eq, :slug_eq, :description_cont, :name_or_description_cont, :on_sale_eq,
            :s, :sorts, :length_gteq, :length_lteq, :beam_gteq, :beam_lteq, :height_gteq, :height_lteq,
            :price_gteq, :price_lteq, :pledge_price_gteq, :pledge_price_lteq, :search_cont,
            :with_dock, :with_cargo, :with_cargo_grids, :in_hangar,
            will_it_fit: [], name_in: [], slug_in: [], manufacturer_in: [], classification_in: [],
            focus_in: [], production_status_in: [], price_in: [], pledge_price_in: [], size_in: [],
            sorts: [], id_not_in: [], id_in: []
          ]
        )[:q].presence || {}
      end
    end
  end
end
