# frozen_string_literal: true

# Drops a record's versions when the record itself is destroyed.
#
# paper_trail keeps versions for a destroyed record on purpose -- that is how a
# deletion stays auditable. For a row carrying somebody's personal data that is
# the wrong default: `object_changes` holds the old values verbatim, so a
# deleted account would leave its email and username behind in an append-only
# table that no erasure path reaches.
#
# Include this where the versioned columns are personal data. Everything else
# keeps paper_trail's behaviour, because a deleted ship or manufacturer is not
# somebody's to erase.
#
# The trade is deliberate: erasure wins over the audit trail here. Who changed
# an account and when is lost with the account, which is the correct answer for
# a deletion request and the wrong one for an investigation. Nothing else on the
# record survives either.
module ErasableVersionsConcern
  extend ActiveSupport::Concern

  included do
    # `after_destroy` rather than `before`: if the destroy is rolled back, the
    # versions are still there. Indexed by (item_type, item_id), and deleted
    # rather than destroyed -- a version has no callbacks worth running and a
    # user's vehicles go one at a time through the same path.
    after_destroy :erase_versions
  end

  private def erase_versions
    PaperTrail::Version.where(item_type: self.class.name, item_id: id).delete_all
  end
end
