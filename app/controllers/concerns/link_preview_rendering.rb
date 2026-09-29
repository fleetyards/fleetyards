# frozen_string_literal: true

# Renders the frontend with the meta a link preview reads, taken from the
# `LinkPreview` the block builds for the record. A record that is not found
# leaves the default meta rather than a 404, as the app decides that itself.
# Rendered through `Frontend::BaseController#render_frontend`, whose no-store
# headers keep the viewer's prefetched data out of any cache.
module LinkPreviewRendering
  extend ActiveSupport::Concern

  private def render_link_preview(record)
    if record.present?
      link_preview = yield record
      @title = link_preview.title
      @og_type = "article"
      @og_image = link_preview_image_url(link_preview.image)
    end

    render_frontend
  end

  private def link_preview_image_url(image)
    case image
    when nil then nil
    when String then helpers.vite_asset_url(image)
    else rails_blob_url(image)
    end
  end
end
