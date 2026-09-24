# frozen_string_literal: true

module SquadronHelper
  # Whether *whoever this render is for* may see the fleet's squadrons. A
  # payload rendered from a model -- every cable broadcast -- goes to many
  # recipients at once, so there is nobody to ask and the answer is no: the
  # client reads the list again on a broadcast rather than patching from it.
  def squadrons_readable_in?(fleet_id)
    return false unless controller.respond_to?(:squadrons_readable_in?)

    controller.squadrons_readable_in?(fleet_id)
  end
end
