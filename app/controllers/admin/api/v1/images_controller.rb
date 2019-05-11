# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ImagesController < ::Admin::Api::BaseController
        def create
          authorize! :create, :admin_api_images

          image_params[:name] = image_params.delete(:file)
          @image = Image.new(image_params)

          return if image.save

          render json: ValidationError.new('image.create', image.errors), status: :bad_request
        end

        def destroy
          authorize! :destroy, image

          return if image.destroy

          render json: ValidationError.new('image.destroy', image.errors), status: :bad_request
        end

        def update
          authorize! :update, image

          return if image.update(image_params)

          render json: ValidationError.new('image.update', image.errors), status: :bad_request
        end

        private def image_params
          @image_params ||= params.transform_keys(&:underscore)
                                  .permit(:name, :file, :gallery_id, :gallery_type, :enabled, :background)
        end

        private def image
          @image ||= Image.find(params[:id])
        end
        helper_method :image
      end
    end
  end
end
