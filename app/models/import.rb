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
class Import < ApplicationRecord
  include AASM

  validates :type, presence: true

  def self.ransackable_attributes(auth_object = nil)
    [
      "aasm_state", "created_at", "failed_at", "finished_at", "id", "id_value", "import",
      "import_data", "info", "input", "output", "started_at", "type", "updated_at", "user_id",
      "version"
    ]
  end

  aasm timestamps: true do
    state :created, initial: true
    state :started
    state :finished
    state :failed

    event :start, after_commit: :notify_admin do
      transitions from: :created, to: :started
    end

    event :finish, after_commit: :notify_admin do
      transitions from: :started, to: :finished
    end

    event :fail, after_commit: :notify_admin do
      transitions from: :created, to: :failed
      transitions from: :started, to: :failed
    end
  end

  def notify_admin
    AdminUser.find_each do |admin_user|
      ::ImportsChannel.broadcast_to(admin_user, to_json)
    end
  end

  def to_json(*_args)
    to_jbuilder_json
  end
end
