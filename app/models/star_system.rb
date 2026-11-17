# frozen_string_literal: true

# A system on RSI's online starmap, all ninety of them, where the game ships
# only a few. Its position is in the map's own unit, which RSI does not name.
class StarSystem < ApplicationRecord
  TYPES = %w[single_star binary].freeze

  has_many :entry_tunnels, class_name: "JumpTunnel", foreign_key: :entry_system_id, inverse_of: :entry_system, dependent: :destroy
  has_many :exit_tunnels, class_name: "JumpTunnel", foreign_key: :exit_system_id, inverse_of: :exit_system, dependent: :destroy

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :position, presence: true
  validates :system_type, inclusion: {in: TYPES}, allow_nil: true
end
