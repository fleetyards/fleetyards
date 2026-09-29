# frozen_string_literal: true

module Frontend
  class ToursController < BaseController
    include LinkPreviewRendering

    def show
      render_link_preview(Tour.find_by(slug: params[:slug])) do |tour|
        LinkPreview.for_tour(tour)
      end
    end

    def join
      render_link_preview(Tour.find_by(invite_token: params[:token])) do |tour|
        LinkPreview.for_tour(tour, via_invite: true)
      end
    end
  end
end
