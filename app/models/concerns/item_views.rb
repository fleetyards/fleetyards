# frozen_string_literal: true

# The renders a catalogue item can be shown by: the eight angles a ship has and
# a holo. An item has no uncoloured silhouette the way a ship's fleetchart
# does, so there is one set rather than a plain and a coloured one.
module ItemViews
  extend ActiveSupport::Concern

  VIEW_ATTACHMENT_NAMES = %i[
    top_view port_view front_view angled_view
    angled_rear_view bottom_view rear_view starboard_view
  ].freeze

  ATTACHMENT_NAMES = (VIEW_ATTACHMENT_NAMES + %i[holo]).freeze

  # Everything `display_image_attr` reads, for a list that shows each item by
  # its picture.
  DISPLAY_IMAGE_PRELOAD = {store_image_attachment: :blob, angled_view_attachment: :blob}.freeze

  included do
    ATTACHMENT_NAMES.each { |name| has_one_attached name }
  end

  class_methods do
    # For a fragment that renders items without keying on each of them: a
    # render attached to one touches only that item.
    def touched_cache_key
      [name, maximum(:updated_at)&.utc&.to_fs(:usec)]
    end
  end

  # What the catalogue shows an item by: its store image, or the angled render
  # when it has none -- the order Model#display_image_attr falls back in.
  def display_image_attr
    if store_image.attached?
      :store_image
    elsif angled_view.attached?
      :angled_view
    end
  end
end
