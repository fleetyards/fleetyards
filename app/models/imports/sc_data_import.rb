# frozen_string_literal: true

# == Schema Information
#
# Table name: imports
#
#  id          :uuid             not null, primary key
#  aasm_state  :string
#  failed_at   :datetime
#  finished_at :datetime
#  import      :string
#  import_data :text
#  info        :text
#  input       :jsonb
#  output      :jsonb
#  started_at  :datetime
#  type        :string
#  version     :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :uuid
#
# Indexes
#
#  index_imports_on_aasm_state           (aasm_state)
#  index_imports_on_aasm_state_and_type  (aasm_state,type)
#  index_imports_on_type                 (type)
#
module Imports
  class ScDataImport < ::Import
    validates :version, presence: true

    def self.current_version
      finished.order(created_at: :asc).last&.version
    end
  end
end
