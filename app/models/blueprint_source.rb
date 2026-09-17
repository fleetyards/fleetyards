# frozen_string_literal: true

# One way a blueprint can be obtained, as one build of the game states it.
#
# A blueprint can carry a lot of these -- 29 on the busiest -- because a pool is
# handed out by every difficulty of every mission that names it. The page groups
# them; the rows stay as the export states them.
# == Schema Information
#
# Table name: blueprint_sources
#
#  id                 :uuid             not null, primary key
#  kind               :string           not null
#  max_standing       :string
#  min_points         :integer
#  min_standing       :string
#  mission_name       :string
#  org_name           :string
#  org_ref            :string
#  pool_group         :string
#  pool_key           :string
#  pool_sc_ref        :string           not null
#  position           :integer          not null
#  source_key         :string
#  weight             :decimal(8, 3)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  blueprint_build_id :uuid             not null
#
# Indexes
#
#  index_blueprint_sources_on_build               (blueprint_build_id)
#  index_blueprint_sources_on_build_and_position  (blueprint_build_id,position) UNIQUE
#  index_blueprint_sources_on_org_name            (org_name)
#
# Foreign Keys
#
#  fk_rails_...  (blueprint_build_id => blueprint_builds.id) ON DELETE => cascade
#
class BlueprintSource < ApplicationRecord
  belongs_to :build, class_name: "BlueprintBuild", inverse_of: :sources,
    foreign_key: :blueprint_build_id

  # A mission a contract generator offers, or the XenoThreat scenario handing
  # pools out by progress points.
  KINDS = %w[contract scenario].freeze

  validates :kind, presence: true, inclusion: {in: KINDS}
  validates :pool_sc_ref, presence: true
  validates :position, presence: true, uniqueness: {scope: :blueprint_build_id}

  # The org is the answer where there is one. Nine handlers sit in a generator
  # naming more than one faction and are left unattributed rather than guessed.
  def attributed?
    org_name.present?
  end
end
