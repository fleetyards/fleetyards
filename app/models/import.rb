# frozen_string_literal: true

# == Schema Information
#
# Table name: imports
#
#  id          :uuid             not null, primary key
#  aasm_state  :string
#  failed_at   :datetime
#  finished_at :datetime
#  info        :text
#  started_at  :datetime
#  type        :string
#  version     :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Import < ApplicationRecord
  include AASM

  validates :version, :type, presence: true

  def self.current_version
    finished.last&.version
  end

  aasm timestamps: true do
    state :created, initial: true
    state :started
    state :finished
    state :failed

    event :start do
      transitions from: :created, to: :started
    end

    event :finish do
      transitions from: :started, to: :finished
    end

    event :fail do
      transitions from: :started, to: :failed
    end
  end
end
