# frozen_string_literal: true

module Loaders
  # Runs after either side of the link changes: a paints import adds
  # ModelPaints, an sc_data load adds paint components.
  class PaintComponentsLinkJob < ::Loaders::BaseJob
    def perform
      ::PaintComponentLinker.new.run
    end
  end
end
