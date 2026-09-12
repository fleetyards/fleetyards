# frozen_string_literal: true

# == Schema Information
#
# Table name: imports
#
#  id                   :uuid             not null, primary key
#  aasm_state           :string
#  add_bundled_vehicles :boolean          default(TRUE), not null
#  cancel_requested_at  :datetime
#  cancelled_at         :datetime
#  failed_at            :datetime
#  finished_at          :datetime
#  import_data          :text
#  info                 :text
#  input                :jsonb
#  output               :jsonb
#  started_at           :datetime
#  type                 :string
#  version              :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  admin_user_id        :uuid
#  hangar_group_id      :uuid
#  user_id              :uuid
#
# Indexes
#
#  index_imports_on_aasm_state_and_type  (aasm_state,type)
#  index_imports_on_admin_user_id        (admin_user_id)
#  index_imports_on_hangar_group_id      (hangar_group_id)
#  index_imports_on_type                 (type)
#  index_imports_on_type_and_id          (type,id)
#  index_imports_on_user_id              (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (admin_user_id => admin_users.id)
#  fk_rails_...  (hangar_group_id => hangar_groups.id) ON DELETE => nullify
#
module Imports
  class UexCommodityPricesImport < ::Import
    belongs_to :admin_user, optional: true
  end
end
