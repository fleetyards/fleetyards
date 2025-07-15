# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ImagesController < ::Admin::Api::BaseController
        before_action :set_image, only: %i[update destroy]

        after_action -> { pagination_header(:images) }, only: [:index]

        def index
          authorize!

          image_query_params["sorts"] = "created_at desc"

          @q = authorized_scope(Image.all).ransack(image_query_params)

          @images = @q.result
            .page(params.fetch(:page, nil))
            .per(params.fetch(:per_page, nil))
        end

        def create
          @image = Image.new(image_create_params)

          authorize! @image, with: ::Admin::ImagePolicy

          return if @image.save

          render json: ValidationError.new("image.create", errors: @image.errors), status: :bad_request
        end

        def update
          return if @image.update(image_params)

          render json: ValidationError.new("image.update", errors: @image.errors), status: :bad_request
        end

        def destroy
          if @image.destroy
            head :no_content
          else
            render json: ValidationError.new("image.destroy", errors: @image.errors), status: :bad_request
          end
        end

        private def image_query_params
          @image_query_params ||= params.permit(q: [
            :gallery_id_eq, :gallery_type_eq
          ]).fetch(:q, {})
        end

        private def image_create_params
          @image_create_params ||= params.transform_keys(&:underscore)
            .permit(
              :file, :gallery_id, :gallery_type
            )
        end

        private def image_params
          @image_params ||= params.transform_keys(&:underscore)
            .permit(
              :enabled, :global, :background, :caption
            )
        end

        private def set_image
          @image = Image.find(params[:id])

          authorize! @image, with: ::Admin::ImagePolicy
        end
      end
    end
  end
end
