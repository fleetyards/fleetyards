class DocsController < ActionController::Base
  layout "docs"

  def index
    respond_to :html
  end
end
