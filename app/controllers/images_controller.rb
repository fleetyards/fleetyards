# frozen_string_literal: true
class ImagesController < ApplicationController
  before_action :set_active_nav

  before_action :authenticate_user!, only: []
  skip_authorization_check

  def index
    @images = Image.enabled
                   .order('images.created_at desc')
                   .page(params.fetch(:page, nil))
                   .per(20)
  end

  private def set_active_nav
    @active_nav = 'images'
  end
end
