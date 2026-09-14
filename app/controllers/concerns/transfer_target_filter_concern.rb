# frozen_string_literal: true

# The opt-in that turns a list of people into a list of people a transfer could
# be addressed to. Two endpoints answer it -- a fleet's roster and a friends
# list -- because a person is picked out of a group rather than out of one flat
# list, and both groups also serve pages that want everybody.
#
# Both spellings, the way `Pagination#per_page_params` reads both: the request
# transformer underscores a query param it validated, and one written any other
# way arrives as it was sent.
module TransferTargetFilterConcern
  extend ActiveSupport::Concern

  private def transfer_targets_only?
    ActiveModel::Type::Boolean.new.cast(params[:transfer_targets] || params[:transferTargets])
  end
end
