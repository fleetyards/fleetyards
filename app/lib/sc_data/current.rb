# frozen_string_literal: true

module ScData
  # Which source the work in hand is reading.
  #
  # `ActiveSupport::CurrentAttributes` rather than a thread-local of our own,
  # because it is reset for us at the end of every request and every job -- a
  # source set for one request cannot leak into the next one on the same thread.
  #
  # Nothing sets this by default. `ScData::Source.current` falls back to the
  # configured default, which is what every existing caller keeps getting.
  class Current < ActiveSupport::CurrentAttributes
    attribute :source
  end
end
