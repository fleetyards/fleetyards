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

    def new
      authorize! :create, :backend_ships
      @ship = Ship.new
    end

    def create
      authorize! :create, :backend_ships
      @ship = Ship.new(ship_params)
      if ship.save
        expire_action controller: :ships, action: :index
        redirect_to backend_ships_path, notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.ship"))
      else
        render 'new', error: I18n.t(:"messages.create.failure", resource: I18n.t(:"resources.ship"))
      end
    end

    def edit
      authorize! :update, ship
    end

    def update
      authorize! :update, ship
      if ship.update(ship_params)
        expire_action controller: :ships, action: :index
        redirect_to backend_ships_path, notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.ship"))
      else
        render "edit", error: I18n.t(:"messages.update.failure", resource: I18n.t(:"resources.ship"))
      end
    end

    def destroy
      authorize! :destroy, ship
      if ship.destroy
        redirect_to backend_ships_path, notice: I18n.t(:"messages.destroy.success", resource: I18n.t(:"resources.ship"))
      else
        redirect_to backend_ships_path, error: I18n.t(:"messages..destroy.failure", resource: I18n.t(:"resources.ship"))
      end
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
          expire_action controller: :ships, action: :index
          ShipsWorker.perform_async
          render json: true
        }
        format.html {
          redirect_to root_path
        }
      end
    end

    def toggle
      authorize! :toggle, ship

      respond_to do |format|
        format.js {
          if ship.update(ship_params)
            expire_action controller: :ships, action: :index
            message = I18n.t(:"messages.disabled.success", resource: I18n.t(:"resources.ship"))
            if ship.enabled?
              message = I18n.t(:"messages.enabled.success", resource: I18n.t(:"resources.ship"))
            end
            render json: {message: message}
          else
            render json: false, status: :bad_request
          end
        }
        format.html {
          redirect_to backend_ships_path
        }
      end
    end

    private def ship_params
      @ship_params ||= params.require(:ship).permit(:name, :enabled)
    end

    private def sort_column
      (Ship.column_names).include?(params[:sort]) ? params[:sort] : "id"
    end
    helper_method :sort_column

    private def ship
      @ship ||= Ship.where(id: params.fetch(:id, nil)).first
    end
    helper_method :ship

    private def set_active_nav
      @active_nav = 'backend-ships'
    end
  end
end
