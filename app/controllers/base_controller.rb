class BaseController < ApplicationController
  skip_authorization_check
  
  before_action :authenticate_user!, only: []

  caches_action :index, layout: false, expires_in: 1.hour
  caches_action :impressum, :privacy, layout: false

  def index
    @ships = Ship.enabled.order("RANDOM()").limit(10)
    @images = Image.enabled.order("RANDOM()").limit(14)
  end

  def impressum
    content = File.read Rails.root.join("texts", I18n.locale.to_s, "impressum.md")
    @text = Metadown.render(content)
  end

  def privacy
    content = File.read Rails.root.join("texts", I18n.locale.to_s, "privacy.md")
    @text = Metadown.render(content)
  end
end
