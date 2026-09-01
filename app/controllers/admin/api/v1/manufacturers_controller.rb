# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ManufacturersController < ::Admin::Api::BaseController
        before_action :set_manufacturer, only: %i[show update destroy]

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.manufacturer", slug: params[:slug]))
        end

        def index
          authorize! with: ::Admin::ManufacturerPolicy

          scope = Manufacturer.with_name

          scope = scope.with_model if manufacturer_query_params.delete(:with_models)

          normalize_sort_params(manufacturer_query_params)
          manufacturer_query_params["sorts"] = sorting_params(Manufacturer, manufacturer_query_params[:sorts])

          q = scope.ransack(manufacturer_query_params)

          @manufacturers = q.result(distinct: true)
            .page(params[:page])
            .per(per_page(Manufacturer))
        end

        def show
        end

        def options
          authorize! with: ::Admin::ManufacturerPolicy

          manufacturer_query_params["sorts"] = "name asc"

          @q = Manufacturer.with_name.ransack(manufacturer_query_params)

          @manufacturers = @q.result(distinct: true)
            .page(params[:page])
            .per(per_page(Manufacturer))
        end

        def create
          @manufacturer = Manufacturer.new(manufacturer_params.merge(icon_override).merge(logo_override))

          authorize! @manufacturer, with: ::Admin::ManufacturerPolicy

          return if @manufacturer.save

          render json: ValidationError.new("manufacturer.create", errors: @manufacturer.errors), status: :bad_request
        end

        def update
          return if @manufacturer.update(manufacturer_params.merge(icon_override).merge(logo_override))

          render json: ValidationError.new("manufacturer.update", errors: @manufacturer.errors), status: :bad_request
        end

        def destroy
          return if @manufacturer.destroy

          render json: ValidationError.new("manufacturer.destroy", errors: @manufacturer.errors), status: :bad_request
        end

        private def set_manufacturer
          @manufacturer = Manufacturer.find(params[:id])

          authorize! @manufacturer, with: ::Admin::ManufacturerPolicy
        end

        # Derived from the upload rather than taken from the request: the flag
        # decides whether the sc_data load may write over this picture, so it
        # follows what actually happened to the attachment. Sending a file
        # claims the icon; clearing it hands the icon back to the export, which
        # refills it on the next load.
        private def icon_override
          return {} unless params.key?(:icon)

          {icon_overridden: params[:icon].present?}
        end

        # The same for the logo, whose other source is RSI's ship matrix:
        # sending a file claims it, clearing it hands it back to the matrix
        # loader, which refills it on the next sync.
        private def logo_override
          return {} unless params.key?(:logo)

          {logo_overridden: params[:logo].present?}
        end

        private def manufacturer_params
          @manufacturer_params ||= params.permit(
            :name, :long_name, :code, :description, :known_for, :logo, :icon, :sc_ref
          )
        end

        private def manufacturer_query_params
          @manufacturer_query_params ||= params.permit(q: [
            :with_models, :name_eq, :name_cont, :slug_eq, :slug_cont, :logo_blank, :id_eq,
            :s, :sorts,
            name_in: [], slug_in: [], id_in: [], s: [], sorts: []
          ]).fetch(:q, {})
        end
      end
    end
  end
end
