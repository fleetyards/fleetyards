# frozen_string_literal: true

module Backend
  class ImagesController < BaseController
    before_action :set_active_nav

    def index
      authorize! :index, :images
      @images = Image.order('created_at desc')
      if params[:ship].present?
        ship = Ship.find_by(slug: params[:ship])
        @images = @images.where(gallery_type: "Ship", gallery_id: ship.id)
      end
      respond_to do |format|
        format.js do
          @images = @images.all
          jq_images = @images.collect(&:to_jq_upload)
          render json: { files: jq_images }.to_json
        end
        format.html do
          @images = @images
                    .page(params.fetch(:page, nil))
                    .per(20)
        end
      end
    end

    def new
      authorize! :new, :images
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
          redirect_to backend_images_path
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
          redirect_to backend_images_path, notice: "success"
        end
      end
    end

    def toggle
      authorize! :toggle, :images

      respond_to do |format|
        format.js do
          if image.update(image_params)
            message = I18n.t(:"messages.disabled.success", resource: I18n.t(:"resources.image"))
            if image.enabled?
              message = I18n.t(:"messages.enabled.success", resource: I18n.t(:"resources.image"))
            end
            render json: { message: message }
          else
            render json: false, status: :bad_request
          end
        end
        format.html do
          redirect_to backend_images_path
        end
      end
    end

    private def image_params
      @image_params ||= params.require(:image).permit(:name, :gallery_id, :gallery_type, :enabled)
    end

    private def sort_column
      Image.column_names.include?(params[:sort]) ? params[:sort] : "id"
    end
    helper_method :sort_column

    private def image
      @image ||= Image.where(id: params.fetch(:id, nil)).first
    end
    helper_method :image

    private def set_active_nav
      @active_nav = 'backend-images'
    end
  end
end
