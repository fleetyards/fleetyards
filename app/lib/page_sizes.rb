# frozen_string_literal: true

# The page sizes every paginated list offers in its per-page dropdown.
module PageSizes
  # The card grid shows 1, 2, 3, 4 or 6 columns, and every one divides 12, so a
  # full page of any of these ends on a full row. Lists of one item per row
  # share them so there is one set to reason about.
  STEPS = [12, 24, 48, 96, 240].freeze

  # A size above the maximum is answered with a 400, so the dropdown never
  # offers one.
  def self.up_to(sizes, max)
    return sizes if max.nil?

    sizes.reject { |size| size.is_a?(Integer) && size > max }
  end
end
