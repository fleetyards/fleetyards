module Backend
  class ShipsController < BaseController
    before_action :set_active_nav

    def index
      authorize! :index, :backend_ships
      @ships = Ship.all
        .order(sort_column + " " + sort_direction)
        .page(params.fetch(:page){nil})
        .per(20)
    end

    def gallery
      authorize! :gallery, :backend_ships
      respond_to do |format|
        format.js {
          images = ship.images.order('created_at desc').all
          jq_images = images.collect { |image| image.to_jq_upload }
          render json: {files: jq_images}.to_json
        }
        format.html {
          # render upload form
        }
      end
    end

    def reload
      authorize! :reload, :backend_ships
      respond_to do |format|
        format.js {
          Resque.enqueue ShipsWorker
          render json: true
        }
        format.html {
          redirect_to root_path
        }
      end
    end

    private def sort_column
      (Ship.column_names).include?(params[:sort]) ? params[:sort] : "id"
    end
    helper_method :sort_column

    private def ship
      @ship ||= Ship.where(slug: params.fetch(:slug, nil)).first
    end
    helper_method :ship

    private def set_active_nav
      @active_nav = 'backend-ships'
    end
  end
end
