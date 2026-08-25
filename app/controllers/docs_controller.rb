class DocsController < ActionController::Base
  layout "docs"

  def index
    respond_to do |format|
      format.html
      # Plain text, not the requested format: an empty JavaScript-typed response
      # to a cross-origin <script> tag trips Rails' same-origin verification.
      format.all { head :not_acceptable, content_type: "text/plain" }
    end
  end
end
