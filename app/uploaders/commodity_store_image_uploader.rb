# frozen_string_literal: true

class CommodityStoreImageUploader < StoreImageUploader
  def default_url(*_args)
    ActionController::Base.helpers.asset_url('fallback/commodity.png', host: Rails.application.secrets[:frontend_endpoint])
  end
end
