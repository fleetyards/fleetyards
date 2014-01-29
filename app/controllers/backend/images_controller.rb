module Backend
  class ImagesController < BaseController
    before_action :set_active_nav

    def index
      authorize! :index, :images
      @images = Image.order('created_at desc')
      respond_to do |format|
        format.js {
          @images = @images.all
          jq_images = @images.collect { |image| image.to_jq_upload }
          render json: {files: jq_images}.to_json
        }
        format.html {
          @images = @images
            .page(params.fetch(:page, nil))
            .per(20)
        }
      end
    end

    def new
      authorize! :new, :images
    end

    def create
      authorize! :create, :images
      respond_to do |format|
        format.js {
          result = []
          params[:files].each do |file|
            params[:image][:name] = file
            result << Image.create(image_params).to_jq_upload
          end
          render json: {files: result}.to_json
        }
        format.html {
          redirect_to backend_images_path
        }
      end
    end

    def destroy
      authorize! :destroy, :images
      @image = Image.find(params[:id])
      @image.destroy
      respond_to do |format|
        format.js {
          render json: true
        }
        format.html {
          redirect_to backend_images_path, notice: "success"
        }
      end
    end

    def enable
      authorize! :enable, :images

      respond_to do |format|
        format.js {
          Image.where(id: params.fetch(:image_ids, nil)).update_all(enabled: true)
          render json: true
        }
        format.html {
          redirect_to backend_images_path
        }
      end
    end

    def disable
      authorize! :disable, :images

      respond_to do |format|
        format.js {
          Image.where(id: params.fetch(:image_ids, nil)).update_all(enabled: false)
          render json: true
        }
        format.html {
          redirect_to backend_images_path
        }
      end
    end

    private def image_params
      @image_params ||= params.require(:image).permit(:name, :gallery_id, :gallery_type)
    end

    private def sort_column
      (Image.column_names).include?(params[:sort]) ? params[:sort] : "id"
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
