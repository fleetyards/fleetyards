# frozen_string_literal: true

module Cleanup
  # An image removed from every text that embedded it -- or never saved into
  # one -- is deleted with its file.
  class MarkdownImagesJob < ::Cleanup::BaseJob
    def perform
      MarkdownImage.unreferenced.find_each(&:destroy)
    end
  end
end
