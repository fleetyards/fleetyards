# frozen_string_literal: true

# == Schema Information
#
# Table name: imports
#
#  id            :uuid             not null, primary key
#  aasm_state    :string
#  failed_at     :datetime
#  finished_at   :datetime
#  import_data   :text
#  info          :text
#  input         :jsonb
#  output        :jsonb
#  started_at    :datetime
#  type          :string
#  version       :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  admin_user_id :uuid
#  user_id       :uuid
#
# Indexes
#
#  index_imports_on_aasm_state_and_type  (aasm_state,type)
#  index_imports_on_admin_user_id        (admin_user_id)
#  index_imports_on_type                 (type)
#
# Foreign Keys
#
#  fk_rails_...  (admin_user_id => admin_users.id)
#
module Imports
  module ScData
    class AllImport < ::Import
      belongs_to :admin_user, optional: true

      validates :version, presence: true

      # The build this source is on, once a load has finished for it -- rather
      # than whichever load finished last, which with two sources configured
      # answers for the wrong one.
      #
      # No environment column is needed to ask it per source: a version names
      # its environment (`4.10.1-ptu.12578875`), so it is already unique across
      # them, and an admin reading the ledger can tell two loads apart by it.
      def self.current_version(source = ::ScData::Source.current)
        finished.where(version: source.version).order(created_at: :asc).last&.version
      end
    end
  end
end
