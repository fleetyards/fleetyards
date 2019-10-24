# frozen_string_literal: true

module Admin
  class ShopsController < BaseController
    before_action :set_active_nav
    after_action :save_filters, only: [:index]

    def index
      authorize! :index, :admin_shops
      @q = Shop.ransack(params[:q])

      @q.sorts = ['name asc', 'id asc'] if @q.sorts.empty?

      @shops = @q.result
                 .page(params.fetch(:page) { nil })
                 .per(40)
    end

    def new
      authorize! :create, :admin_shops
      @shop = Shop.new
    end

    def create
      authorize! :create, :admin_shops
      @shop = Shop.new(shop_params)
      if shop.save
        redirect_to edit_admin_shop_path(shop.id), notice: I18n.t(:"messages.create.success", resource: I18n.t(:"resources.shop"))
      else
        render 'new', error: I18n.t(:"messages.create.failure", resource: I18n.t(:"resources.shop"))
      end
    end

    def edit
      authorize! :update, shop
    end

    def update
      authorize! :update, shop
      if shop.update(shop_params)
        redirect_to edit_admin_shop_path(shop.id), notice: I18n.t(:"messages.update.success", resource: I18n.t(:"resources.shop"))
      else
        render 'edit', error: I18n.t(:"messages.update.failure", resource: I18n.t(:"resources.shop"))
      end
    end

    def destroy
      authorize! :destroy, shop
      if shop.destroy
        redirect_to admin_shops_path(params: index_back_params, anchor: shop.id), notice: I18n.t(:"messages.destroy.success", resource: I18n.t(:"resources.shop"))
      else
        redirect_to admin_shops_path(params: index_back_params, anchor: shop.id), error: I18n.t(:"messages..destroy.failure", resource: I18n.t(:"resources.shop"))
      end
    end

    private def shop_params
      @shop_params ||= params.require(:shop).permit(
        :name, :station_id, :store_image, :shop_type, :store_image_cache, :remove_store_image, :hidden,
        :rental, :buying, :selling,
        shop_commodities_attributes: %i[
          id commodity_item_selected buy_price sell_price rent_price_1_day rent_price_7_days rent_price_30_days price_per_unit _destroy
        ]
      )
    end

    private def save_filters
      session[:shops_filters] = params[:q]
      session[:shops_page] = params[:page]
    end

    private def index_back_params
      @index_back_params ||= ActionController::Parameters.new(
        q: session[:shops_filters],
        page: session[:shops_page]
      ).permit!.delete_if { |_k, v| v.nil? }
    end
    helper_method :index_back_params

    private def shop_commodities
      @shop_commodities ||= shop.shop_commodities.sort_by do |item|
        if item.commodity_item_type == 'Equipment'
          [item.commodity_item_type, item.commodity_item.equipment_type, item.commodity_item.name, item.created_at]
        elsif item.commodity_item_type.present?
          [item.commodity_item_type, nil, item.commodity_item.name, item.created_at]
        else
          []
        end
      end
    end
    helper_method :shop_commodities

    private def shop
      @shop ||= Shop.where(id: params.fetch(:id, nil)).first
    end
    helper_method :shop

    private def set_active_nav
      @active_nav = 'admin-shops'
    end
  end
end
