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
#  alignment          :string
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

  # Which side of the law the org handing the recipe out sits on. Null where the
  # generator names more than one faction and the source is left unattributed.
  ALIGNMENTS = %w[lawful neutral outlaw].freeze

  # The export states a boolean and nothing more: `entityLawful` on the org's
  # reputation record, 29 true against 9 false across the 38 that exist. There
  # is no third value anywhere in the game files -- `Faction.factionType` reads
  # only Lawful, Unlawful, PrivateSecurity and LawEnforcement, and the
  # `_RepUI_Area` string is prose that says "UEE" for Vaughn, an assassination
  # broker -- so "neutral" is ours to name, and these are the orgs it is named
  # for. Each hands work to both sides rather than to one:
  #
  #   wikelo      an alien barter trader whose Emporium sits in Pyro and who
  #               takes anyone's goods, marked lawful only for want of anything
  #               else to mark it
  #   battaglia   a mercenary-guild contact operating out of Nyx, an
  #               unaffiliated system, and the only guild faction whose record
  #               carries no `lawful_`/`unlawful_` prefix
  #   citizensforprosperity
  #               Pyro's own civic and security body, outside UEE jurisdiction
  #               entirely -- the export agrees on the substance and puts its
  #               area at "Unclaimed Systems"
  #
  # Matched on the faction record's name rather than its GUID or display name:
  # the one is an identity the export may reissue, the other is localised.
  NEUTRAL_ORG_KEYS = %w[
    factionreputation_wikelo
    factionreputation_battaglia
    factionreputation_lawful_citizensforprosperity
  ].freeze

  validates :kind, presence: true, inclusion: {in: KINDS}
  validates :alignment, inclusion: {in: ALIGNMENTS}, allow_nil: true
  validates :pool_sc_ref, presence: true
  validates :position, presence: true, uniqueness: {scope: :blueprint_build_id}

  # What the loader writes. Kept here rather than in the loader so the rule and
  # the list it reads sit together, and so a curation change is a model change
  # that the next load picks up without a re-parse.
  def self.alignment_for(org_key:, lawful:)
    return "neutral" if org_key.present? && NEUTRAL_ORG_KEYS.include?(org_key)
    return if lawful.nil?

    lawful ? "lawful" : "outlaw"
  end

  # The org is the answer where there is one. Nine handlers sit in a generator
  # naming more than one faction and are left unattributed rather than guessed.
  def attributed?
    org_name.present?
  end
end
