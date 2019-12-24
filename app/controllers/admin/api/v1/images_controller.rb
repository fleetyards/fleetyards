# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ImagesController < ::Admin::Api::BaseController
        after_action -> { pagination_header(:images) }, only: [:index]

        def index
          authorize! :index, :admin_api_images

          image_query_params['sorts'] = 'created_at desc'

          @q = Image.ransack(image_query_params)

          @images = @q.result
                      .page(params.fetch(:page, nil))
                      .per(40)
        end

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

        private def image_query_params
          @image_query_params ||= query_params(
            :gallery_id_eq, :gallery_type_eq
          )
        end

        private def image_params
          @image_params ||= params.transform_keys(&:underscore)
                                  .permit(
                                    :name, :file, :gallery_id, :gallery_type, :enabled,
                                    :global, :background
                                  )
        end

        private def image
          @image ||= Image.find(params[:id])
        end
        helper_method :image
      end
    end
  end
end
