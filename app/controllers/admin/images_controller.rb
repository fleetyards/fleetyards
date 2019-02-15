# frozen_string_literal: true

module Admin
  class ImagesController < BaseController
    before_action :set_active_nav

    def index
      authorize! :index, :images
      respond_to do |format|
        format.js do
          @images = Image.all
          jq_images = @images.collect(&:to_jq_upload)
          render json: { files: jq_images }.to_json
        end
        format.html do
          @q = Image.ransack(params[:q])
          @images = @q.result
                      .page(params.fetch(:page, nil))
                      .per(40)
        end
      end
    end

    def create
      authorize! :create, :images
      respond_to do |format|
        format.js do
          result = []
          params[:files].each do |file|
            params[:image][:name] = file
            result << Image.create(image_params).to_jq_upload
          end
          render json: { files: result }.to_json
        end
        format.html do
          redirect_to admin_images_path
        end
      end
    end

    def destroy
      authorize! :destroy, :images
      @image = Image.find(params[:id])
      @image.destroy
      respond_to do |format|
        format.js do
          render json: true
        end
        format.html do
          redirect_to admin_images_path, notice: 'success'
        end
      end
    end

    def toggle
      authorize! :toggle, :images

      respond_to do |format|
        format.js do
          if image.update(image_params)
            message = I18n.t(:"messages.disabled.success", resource: I18n.t(:"resources.image"))
            message = I18n.t(:"messages.enabled.success", resource: I18n.t(:"resources.image")) if image.enabled?
            render json: { message: message }
          else
            render json: false, status: :bad_request
          end
        end
        format.html do
          redirect_to admin_images_path
        end
      end
    end

    def toggle_background
      authorize! :toggle, :images

      respond_to do |format|
        format.js do
          if image.update(image_params)
            message = I18n.t(:"messages.background_disabled.success", resource: I18n.t(:"resources.image"))
            message = I18n.t(:"messages.background_enabled.success", resource: I18n.t(:"resources.image")) if image.enabled?
            render json: { message: message }
          else
            render json: false, status: :bad_request
          end
        end
        format.html do
          redirect_to admin_images_path
        end
      end
    end

    private def image_params
      @image_params ||= params.require(:image).permit(:name, :gallery_id, :gallery_type, :enabled, :background)
    end

    private def image
      @image ||= Image.where(id: params.fetch(:id, nil)).first
    end
    helper_method :image

    private def set_active_nav
      @active_nav = 'admin-images'
    end
  end
end
