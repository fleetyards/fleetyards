# frozen_string_literal: true

# Renders the frontend with the meta a link preview reads, taken from the
# `LinkPreview` the block builds for the record. A record that is not found
# leaves the default meta rather than a 404, as the app decides that itself.
module LinkPreviewRendering
  extend ActiveSupport::Concern

  private def render_link_preview(record)
    if record.present?
      link_preview = yield record
      @title = link_preview.title
      @og_type = "article"
      @og_image = rails_blob_url(link_preview.image) if link_preview.image
    end

    respond_to do |format|
      format.html { render "frontend/index", status: :ok }
      format.all { redirect_to "/404" }
    end
  end
end
