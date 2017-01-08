class ImagesController < ApplicationController
  before_action :set_active_nav

  before_filter :authenticate_user!, only: []
  skip_authorization_check

  caches_action :index, layout: false, cache_path: Proc.new { |c| c.params }

  def index
    authorize! :index, :images
    @images = Image.enabled
      .order('images.created_at desc')
      .page(params.fetch(:page, nil))
      .per(20)
  end

  private def set_active_nav
    @active_nav = 'images'
  end
end
