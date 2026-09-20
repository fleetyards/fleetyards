# frozen_string_literal: true

# == Schema Information
#
# Table name: imports
#
#  id                        :uuid             not null, primary key
#  aasm_state                :string
#  add_bundled_vehicles      :boolean          default(TRUE), not null
#  cancel_requested_at       :datetime
#  cancelled_at              :datetime
#  failed_at                 :datetime
#  finished_at               :datetime
#  import_data               :text
#  info                      :text
#  input                     :jsonb
#  output                    :jsonb
#  started_at                :datetime
#  type                      :string
#  unmatched_vehicles_action :string           default("wishlist"), not null
#  version                   :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  admin_user_id             :uuid
#  hangar_group_id           :uuid
#  unmatched_hangar_group_id :uuid
#  user_id                   :uuid
#
# Indexes
#
#  index_imports_on_aasm_state_and_type        (aasm_state,type)
#  index_imports_on_admin_user_id              (admin_user_id)
#  index_imports_on_hangar_group_id            (hangar_group_id)
#  index_imports_on_type_and_id                (type,id)
#  index_imports_on_unmatched_hangar_group_id  (unmatched_hangar_group_id)
#  index_imports_on_user_id                    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (admin_user_id => admin_users.id)
#  fk_rails_...  (hangar_group_id => hangar_groups.id) ON DELETE => nullify
#  fk_rails_...  (unmatched_hangar_group_id => hangar_groups.id) ON DELETE => nullify
#
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
      def self.last_finished_for(source)
        finished.where(version: source.version).order(created_at: :asc).last
      end
    end
  end
end
