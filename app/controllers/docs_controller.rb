class DocsController < ActionController::Base
  layout "docs"

  def index
    respond_to do |format|
      format.html
      format.all { head :not_acceptable }
    end
  end
end
