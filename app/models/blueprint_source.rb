# frozen_string_literal: true

# One way a blueprint can be obtained, as one build of the game states it.
#
# A blueprint can carry a lot of these -- 29 on the busiest -- because a pool is
# handed out by every difficulty of every mission that names it. The page groups
# them; the rows stay as the export states them.
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

  # The contracts that hand this source out, matched on everything the source
  # states about its contract: the pool, the generator, the title, the standing
  # band and the org. The parse folds a contract offered identically in several
  # systems, or in two regions of one, into a single source, so one source can
  # stand for several missions -- each a contract of its own.
  def self.preload_missions(sources)
    sources = sources.to_a
    contracts = sources.select { |source| source.kind == "contract" }
    sources.each { |source| source.missions = [] }
    return sources if contracts.empty?

    served = ::GameMission.served_source
    candidates = ::GameMissionBuild.current(served)
      .where("blueprint_pool_refs && ARRAY[?]::text[]", contracts.map(&:pool_sc_ref).uniq)
      .where(game_mission_id: ::GameMission.named(served).select(:id))
      .to_a

    missions = ::GameMission.preload_systems(
      ::GameMission.where(id: candidates.map(&:game_mission_id)).includes(:build, :last_build)
    ).index_by(&:id)

    contracts.each do |source|
      source.missions = candidates
        .select { |build| source.describes?(build) }
        .filter_map { |build| missions[build.game_mission_id] }
        .sort_by { |mission| [mission.systems.map(&:name), mission.sc_key] }
    end

    sources
  end

  attr_writer :missions

  def missions
    ::BlueprintSource.preload_missions([self]) unless defined?(@missions)
    @missions
  end

  def describes?(mission_build)
    mission_build.blueprint_pool_refs.include?(pool_sc_ref) &&
      mission_build.generator_key == source_key &&
      mission_build.name == mission_name &&
      mission_build.min_standing == min_standing &&
      mission_build.max_standing == max_standing &&
      mission_build.org_ref == org_ref
  end

  # The org is the answer where there is one. Nine handlers sit in a generator
  # naming more than one faction and are left unattributed rather than guessed.
  def attributed?
    org_name.present?
  end
end
