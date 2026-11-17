# frozen_string_literal: true

class JumpTunnel < ApplicationRecord
  SIZES = %w[small medium large].freeze

  belongs_to :entry_system, class_name: "StarSystem", inverse_of: :entry_tunnels
  belongs_to :exit_system, class_name: "StarSystem", inverse_of: :exit_tunnels

  validates :entry_system_id, uniqueness: {scope: :exit_system_id}
  validates :size, inclusion: {in: SIZES}, allow_nil: true
end
