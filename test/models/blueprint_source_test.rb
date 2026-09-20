# frozen_string_literal: true

require "test_helper"

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
class BlueprintSourceTest < ActiveSupport::TestCase
  # The export states a boolean and nothing else, so two of the three values
  # fall out of it and the third is ours.
  test ".alignment_for reads the export's lawful flag" do
    assert_equal "lawful", BlueprintSource.alignment_for(
      org_key: "factionreputation_lawful_foxwellenforcement", lawful: true
    )
    assert_equal "outlaw", BlueprintSource.alignment_for(
      org_key: "factionreputation_unlawful_headhunters", lawful: false
    )
  end

  # Wikelo is marked lawful by the export for want of anything else to mark it,
  # so the curated list has to win over the flag rather than only fill in for a
  # missing one.
  test ".alignment_for prefers the curated list over the flag" do
    assert_equal "neutral", BlueprintSource.alignment_for(
      org_key: "factionreputation_wikelo", lawful: true
    )
  end

  # Nine source entries sit in a generator naming more than one faction and are
  # left unattributed. A guess there would be worse than a blank.
  test ".alignment_for says nothing about a source with no org" do
    assert_nil BlueprintSource.alignment_for(org_key: nil, lawful: nil)
    assert_nil BlueprintSource.alignment_for(org_key: "factionreputation_ruto", lawful: nil)
  end

  test "every curated neutral org is spelled the way a record key is" do
    BlueprintSource::NEUTRAL_ORG_KEYS.each do |key|
      assert_match(/\Afactionreputation_[a-z0-9_]+\z/, key)
    end
  end

  test "rejects an alignment that is not one of the three" do
    source = build(:blueprint_source, alignment: "uee")

    assert_not source.valid?
    assert_includes source.errors.attribute_names, :alignment
  end

  test "accepts no alignment at all" do
    assert_predicate build(:blueprint_source, alignment: nil), :valid?
  end
end
