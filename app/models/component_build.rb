# frozen_string_literal: true

# == Schema Information
#
# Table name: component_builds
#
#  id                    :uuid             not null, primary key
#  ammunition            :string
#  category              :string
#  component_class       :string
#  component_sub_type    :string
#  component_type        :string
#  description           :text
#  durability            :string
#  environment           :string           not null
#  grade                 :string
#  heat_connection       :string
#  hidden                :boolean          default(FALSE)
#  inventory_consumption :string
#  item_class            :integer
#  item_type             :string
#  name                  :string
#  power_connection      :string
#  size                  :string
#  tracking_signal       :integer
#  type_data             :string
#  version               :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  component_id          :uuid             not null
#  manufacturer_id       :uuid
#
# Indexes
#
#  index_component_builds_on_component_and_build              (component_id,environment,version) UNIQUE
#  index_component_builds_on_component_id                     (component_id)
#  index_component_builds_on_environment_and_component_class  (environment,component_class)
#  index_component_builds_on_environment_and_item_type        (environment,item_type)
#  index_component_builds_on_environment_and_version          (environment,version)
#  index_component_builds_on_manufacturer_id                  (manufacturer_id)
#
# Foreign Keys
#
#  fk_rails_...  (component_id => components.id) ON DELETE => cascade
#
# What one build of the game says about a component.
#
# The columns here are exactly the ones `ScData::Loader::ItemsLoader` writes.
# Everything that identifies the component, or that a person set by hand, stays on
# Component -- so a load can rewrite a build without touching the row a hardpoint,
# a model paint or an uploaded icon hangs off.
class ComponentBuild < ApplicationRecord
  belongs_to :component
  belongs_to :manufacturer, optional: true

  # How many builds of one environment are kept. Enough to diff a patch against
  # the one before it, and to compare a bad load with what it replaced, without
  # the table growing with every patch forever.
  BUILDS_RETAINED = 3

  # Everything a build says, as opposed to what identifies the component. Taken
  # from Component's own paper_trail list, which already named the specs that move
  # between builds, plus `category` -- the loader writes it and it decides
  # `hidden`, so it belongs to the build even though paper_trail skips it.
  #
  # The data migration carries its own copy on purpose: a migration has to keep
  # running against the schema of its own moment, not this list as it later
  # becomes.
  FACTS = %i[
    manufacturer_id name description size grade item_type item_class
    component_class component_type component_sub_type category type_data
    durability power_connection heat_connection ammunition
    inventory_consumption tracking_signal hidden
  ].freeze

  # The facts Component reads through its build. `manufacturer_id` and `hidden`
  # are held back for the same reasons as on equipment: the association reads the
  # column, and `visible` moves with the filters rather than with the readers.
  READ_THROUGH = (FACTS - %i[manufacturer_id hidden]).freeze

  # The same serialization and enums Component declares, because a build row
  # holding `0` has to read as `stealth` here too, and a YAML string has to come
  # back as the structure it encodes.
  #
  # All six of Component's serialized columns, not the one that caught the eye:
  # missing `type_data` alone made the weapons endpoint call `dig` on a raw YAML
  # string, because the reader falls through to the column only on nil and a
  # string is not nil.
  serialize :type_data, coder: YAML
  serialize :durability, coder: YAML
  serialize :power_connection, coder: YAML
  serialize :heat_connection, coder: YAML
  serialize :ammunition, coder: YAML
  serialize :inventory_consumption, coder: YAML

  enum :item_class,
    {stealth: 0, civilian: 1, industrial: 2, military: 3, competition: 4}

  enum :tracking_signal,
    {infrared: 0, cross_section: 1, electromagnetic: 2}

  validates :environment, presence: true
  validates :version, presence: true
  validates :component_id, uniqueness: {scope: [:environment, :version]}

  # Every build this environment still has, newest first.
  scope :for_source, ->(source = ::ScData::Source.current) {
    where(environment: source.environment)
  }

  # The one build the environment is on. `ScData::Source` names the version
  # exactly, so this needs no ordering or subselect.
  scope :current, ->(source = ::ScData::Source.current) {
    where(environment: source.environment, version: source.version)
  }

  # The versions worth keeping for one environment, ordered by when they first
  # appeared. Re-loading a build updates its rows in place, so `created_at` is
  # when that build first landed rather than when it was last touched.
  def self.retained_versions(environment, keep: BUILDS_RETAINED)
    where(environment:)
      .group(:version)
      .minimum(:created_at)
      .sort_by { |_version, first_seen| first_seen }
      .last(keep)
      .map(&:first)
  end
end
