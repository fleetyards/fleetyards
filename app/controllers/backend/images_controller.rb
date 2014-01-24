module Backend
  class ImagesController < BaseController

    def index
      authorize! :index, :images
      respond_to do |format|
        format.js {
          @images = Image.order('created_at desc').all
          jq_images = @images.collect { |image| image.to_jq_upload }
          render json: {files: jq_images}.to_json
        }
        format.html {
          redirect_to root_path
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
          redirect_to root_path
        }
      end
    end

    def destroy
      authorize! :destroy, :images

      respond_to do |format|
        format.js {
          @image = Image.find(params[:id])
          @image.destroy
          render :json => true
        }
        format.html {
          redirect_to root_path
        }
      end
    end

    private def image_params
      @image_params ||= params.require(:image).permit(:name, :gallery_id, :gallery_type)
    end
  end
end
