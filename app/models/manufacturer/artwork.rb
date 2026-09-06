# frozen_string_literal: true

class Manufacturer
  # Where the artwork stamp is held for the request or the job in hand.
  #
  # `ActiveSupport::CurrentAttributes` rather than a memo of our own, because
  # Rails resets it at the end of every unit of work: a list of thirty ships
  # reads the stamp once, and the value cannot survive into the next request on
  # the same thread. Same reasoning as ScData::Current.
  class Artwork < ActiveSupport::CurrentAttributes
    attribute :version
  end
end
