# frozen_string_literal: true

# The page sizes every paginated list offers in its per-page dropdown.
module PageSizes
  # The card grid shows 1, 2, 3, 4 or 6 columns, and every one divides 12, so a
  # full page of any of these ends on a full row. Lists of one item per row
  # share them so there is one set to reason about.
  STEPS = [12, 24, 48, 96, 144, 240].freeze

  # The steps a list whose maximum is `max` can offer: `per_page` answers a size
  # above the maximum with a 400.
  def self.up_to(max, sizes = STEPS)
    return sizes if max.nil?

    sizes.reject { |size| size.is_a?(Integer) && size > max }
  end

  # The `per_page_steps` macro beside Kaminari's `paginates_per`, for anything
  # that pages: a model, or a list built in memory.
  module Declarable
    def per_page_steps(val = :none)
      if val == :none
        defined?(@_per_page_steps) && @_per_page_steps
      else
        @_per_page_steps = val
      end
    end
  end
end
