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
  class ModelsImport < ::Import
    belongs_to :admin_user, optional: true
  end
end
