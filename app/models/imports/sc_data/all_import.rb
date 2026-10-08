# frozen_string_literal: true

module Imports
  module ScData
    class AllImport < ::Import
      belongs_to :admin_user, optional: true

      validates :version, presence: true

      # Which parsed tree this load actually read, as the digest the parser
      # wrote into it. The version alone cannot answer that: a parser change
      # rewrites the tree and leaves the version where it was.
      #
      # On `input` rather than a column of its own -- `imports` is one STI table
      # shared with every user-facing import, and this is a fact about one
      # subtype's payload, which is what `input` is for.
      #
      # Blank on every load recorded before this shipped, which is what makes
      # the first check after it reload once per source.
      store_accessor :input, :tree_checksum

      # The build this source is on, once a load has finished for it -- rather
      # than whichever load finished last, which with two sources configured
      # answers for the wrong one.
      #
      # No environment column is needed to ask it per source: a version names
      # its environment (`4.10.1-ptu.12578875`), so it is already unique across
      # them, and an admin reading the ledger can tell two loads apart by it.
      # The version a reader is actually being answered from, which is the last
      # one we finished importing -- during the window between a config bump and
      # its load that is the patch behind, not the bumped version nothing has
      # rows for yet.
      def self.current_version(source = ::ScData::Source.current)
        served = source.served
        finished.where(version: served.version).order(created_at: :asc).last&.version ||
          (served.version if served != source)
      end

      # The load `CheckJob` compares a tree against: the last one that finished
      # for this build, whose `tree_checksum` says which tree it read.
      #
      # By completion rather than creation. Nothing serialises a load -- the
      # nightly check and the admin reload can both enqueue one -- so two can
      # overlap, and the one started second is not always the one that finished
      # second. The question here is which tree the database currently reflects,
      # and that is whichever load wrote last.
      #
      # Nulls last, then newest created: a record moved to `finished` without
      # going through the state machine has no `finished_at`, and Postgres sorts
      # nulls first on a descending order, which would hand back exactly the
      # record that knows least.
      def self.last_finished_for(source)
        finished
          .where(version: source.version)
          .order(Arel.sql("finished_at DESC NULLS LAST"))
          .order(created_at: :desc)
          .first
      end
    end
  end
end
